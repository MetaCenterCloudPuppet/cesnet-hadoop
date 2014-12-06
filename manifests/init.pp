# == Class: hadoop
#
# Setup Hadoop Cluster. Security and Kerberos are supported.
#
# === Parameters
#
# [*hdfs_hostname*] (localhost)
#   Hadoop Filesystem Name Node machine.
#
# [*yarn_hostname*] (localhost)
#   Yarn machine (with Resource Manager and Job History services).
#
# [*slaves*] (localhost)
#   Array of slave node hostnames.
#
# [*frontends*]
#   Array of frontend hostnames. Used *slaves* by default.
#
# [*cluster_name*] ("")
#   Name of the cluster, used during initial formatting of HDFS.
#
# [*realm*]
#   Kerberos realm. Required parameter, empty string disables Kerberos authentication.
#   To enable security, there are required:
#   * installed Kerberos client (Debian: krb5-user/heimdal-clients; RedHat: krb5-workstation)
#   * configured Kerberos client (/etc/krb5.conf, /etc/krb5.keytab)
#   * /etc/security/keytab/dn.service.keytab (on data nodes)
#   * /etc/security/keytab/jhs.service.keytab (on job history node)
#   * /etc/security/keytab/nm.service.keytab (on node manager nodes)
#   * /etc/security/keytab/nn.service.keytab (on name nodes)
#   * /etc/security/keytab/rm.service.keytab (on resource manager node)
#
# [*namenode_hostname*] (undef)
#   Name Node machine. Used *hdfs_hostname* by default.
#
# [*resourcemanager_hostname*] (undef)
#   Resource Manager machine. Used *yarn_hostname* by default.
#
# [*historyserver_hostname*] (undef)
#   History Server machine. Used *yarn_hostname* by default.
#
# [*nodemanager_hostnames*] (undef)
#   Array of Node Manager machines. Used *slaves* by default.
#
# [*datanodes_hostnames*] (undef)
#   Array of Data Node machines. Used *slaves* by default.
#
# [*hdfs_dirs*] (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])
#  Directory prefixes to store the data.
#    - namenode:
#  - name table (fsimage) and DFS data blocks
#  - /${user.name}/dfs/namenode or /${user.name}/dfs/name suffix is always added
#       - If there is multiple directories, then the name table is replicated in all of the directories, for redundancy.
#    - datanode:
#  - DFS data blocks
#  - /${user.name}/dfs/datanode suffix is always added
#  - If there is multiple directories, then data will be stored in all directories, typically on different devices.
#  When adding a new directory, you need to replicate the contents from some of the other ones. Or set dfs.namenode.name.dir.restore to true and create NEW_DIR/hdfs/dfs/namenode with proper owners.
#
# [*properties*] (see params.pp)
#   "Raw" properties for hadoop cluster. "::undef" will remove property from defaults, empty string sets empty value.
#
# [*descriptions*] (see params.pp)
#   Descriptions for the properties, just for cuteness.
#
# [*features*] ()
#   Enable additional features:
#   - rmstore: resource manager recovery using state-store; this requires HDFS datanodes already running ==> keep disabled on initial setup!
#   - restarts: regular resource manager restarts (MIN HOUR MDAY MONTH WDAY); it shall never be restarted, but it may be needed for refreshing Kerberos tickets
#   - krbrefresh: use and refresh Kerberos credential cache (MIN HOUR MDAY MONTH WDAY); beware there is a small race-condition during refresh
#     (TODO: Debian not supported)
#   - authorization - enable authorization and select authorization rules (permit, limit); recommended to try 'permit' rules first
#   - yellowmanager - script in /usr/local to start/stop all daemons relevant for given node
#
# [*perform*] (false)
#   Launch all installation and setup here, from hadoop class.
#
# === Example
#
#class{"hadoop":
#  hdfs_hostname => "hdfs.example.com",
#  yarn_hostname => "yarn.example.com",
#  slaves => [ "node1.example.com", "node2.example.com", "node3.example.com" ],
#  frontends => [ "node1.example.com" ],
#  realm => "EXAMPLE.COM",
#  hdfs_dirs => [ "/var/lib/hadoop-hdfs", "/data2", "/data3", "/data4" ],
#  cluster_name => "MY_CLUSTER_NAME",
#  properties => {
#    'dfs.replication' => 2,
#  },
#  descriptions => {
#    'dfs.replication' => "default number of replicas",
#  },
#  features => {
#    rmstore => true,
#    krbrefresh => '00 */4 * * *',
#    authorization => 'limit',
#    yellowmanager => true,
#  },
#  perform => true,
#}
#
# Alternatively you can omit perform parameter (or use perform => false) and include particular nodes (it may be preferred in sense of best practices):
#
# class{"hadoop":
#   ...
#   perform => false,
# }
# node 'hdfs.example.com' {
#   include hadoop::namenode
# }
# node 'yarn.example.com' {
#   include hadoop::resourcemanager
#   include hadoop::historyserver
# }
# node 'node1.example.com' {
#   include hadoop::datanode
#   include hadoop::nodemanager
#   include hadoop::frontend
# }
# node 'node2.example.com', 'node3.example.com' {
#   include hadoop::datanode
#   include hadoop::nodemanager
# }
#
class hadoop (
  $hdfs_hostname = $params::hdfs_hostname,
  $yarn_hostname = $params::yarn_hostname,
  $slaves = $params::slaves,
  $frontends = [],
  $cluster_name = $params::cluster_name,
  $realm,
  $authorization = $params::authorization,

  $namenode_hostname = undef,
  $resourcemanager_hostname = undef,
  $historyserver_hostname = undef,
  $nodemanager_hostnames = undef,
  $datanode_hostnames = undef,

  $hdfs_dirs = $params::hdfs_dirs,
  $properties = undef,
  $descriptions = undef,
  $features = $params::features,
  $perform = $params::perform,
) inherits hadoop::params {
  include 'stdlib'

  # detailed deployment bases on convenient parameters
  if $namenode_hostname { $nn_hostname = $namenode_hostname }
  else { $nn_hostname = $hdfs_hostname }
  if $resourcemanager_hostname { $rm_hostname = $resourcemanager_hostname }
  else { $rm_hostname = $yarn_hostname }
  if $historyserver_hostname { $hs_hostname = $historyserver_hostname }
  else { $hs_hostname = $yarn_hostname }
  if $nodemanager_hostnames { $nm_hostnames = $nodemanager_hostnames }
  else { $nm_hostnames = $slaves }
  if $datanode_hostnames { $dn_hostnames = $datanode_hostnames }
  else { $dn_hostnames = $slaves }
  if $frontends { $frontend_hostnames = $frontends }
  else { $frontend_hostnames = $slaves }

  if $::fqdn == $nn_hostname {
    $daemon_namenode = 1
    $mapred_user = 1

  }

  if $::fqdn == $rm_hostname {
    $daemon_resourcemanager = 1
  }

  if $::fqdn == $hs_hostname {
    $daemon_historyserver = 1
  }

  if member($nm_hostnames, $::fqdn) {
    $daemon_nodemanager = 1
  }

  if member($dn_hostnames, $::fqdn) {
    $daemon_datanode = 1
  }

  if member($frontend_hostnames, $::fqdn) {
    $frontend = 1
  }

  $dyn_properties = {
    'fs.default.name' => "hdfs://${nn_hostname}:8020",
    'yarn.resourcemanager.hostname' => $rm_hostname,
    'yarn.nodemanager.aux-services' => 'mapreduce_shuffle',
    'yarn.nodemanager.aux-services.mapreduce_shuffle.class' => 'org.apache.hadoop.mapred.ShuffleHandler',
    'mapreduce.jobhistory.address' => "${hs_hostname}:10020",
    'mapreduce.jobhistory.webapps.address' => "${hs_hostname}:19888",
  }
  if ($hadoop::realm) {
    $sec_properties = {
      'hadoop.security.authentication' => 'kerberos',
      'hadoop.rcp.protection' => 'integrity',
      # probably not needed:
      # RULE:[2:$1;$2@$0](^rm;.*@<%= @realm -%>$)s/^.*$/yarn/
      'hadoop.security.auth_to_local' => "
RULE:[2:\$1;\$2@\$0](^jhs;.*@${realm}$)s/^.*$/mapred/
RULE:[2:\$1;\$2@\$0](^[nd]n;.*@${realm}$)s/^.*$/hdfs/
DEFAULT
",
      'dfs.datanode.address' => '0.0.0.0:1004',
      'dfs.datanode.http.address' => '0.0.0.0:1006',
      'dfs.block.access.token.enable' => true,
      'dfs.namenode.kerberos.principal' => "nn/_HOST@${hadoop::realm}",
      'dfs.namenode.kerberos.https.principal' => "host/_HOST@${hadoop::realm}",
      'dfs.datanode.kerberos.principal' => "dn/_HOST@${hadoop::realm}",
      'dfs.datanode.kerberos.https.principal' => "host/_HOST@${hadoop::realm}",
      'dfs.encrypt.data.transfer' => false,
      'dfs.webhdfs.enabled' => false,
      'dfs.web.authentication.kerberos.principal' => "HTTP/_HOST@${hadoop::realm}",
      'mapreduce.jobhistory.principal' => "jhs/_HOST@${hadoop::realm}",
      'yarn.resourcemanager.principal' => "rm/_HOST@${hadoop::realm}",
      'yarn.nodemanager.principal' => "nm/_HOST@${hadoop::realm}",
      'yarn.nodemanager.container-executor.class' => 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor',
      'yarn.nodemanager.linux-container-executor.group' => 'hadoop',
    }
  }
  if ($hadoop::features["authorization"]) {
    $auth_properties = {
      'hadoop.security.authorization' => true,
    }
  } else {
    $auth_properties = {
      'hadoop.security.authorization' => false,
    }
  }
  if ($hadoop::features["rmstore"]) {
    $rm_ss_properties = {
      'yarn.resourcemanager.recovery.enabled' => true,
      'yarn.resourcemanager.store.class' => 'org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore',
      'yarn.resourcemanager.fs.state-store.uri' => "hdfs://${nn_hostname}:8020/rmstore",
    }
  } else {
    $rm_ss_properties = {}
  }

  $props = merge($params::properties, $dyn_properties, $sec_properties, $auth_properties, $rm_ss_properties, $properties)
  $descs = merge($params::descriptions, $descriptions)

  if $hadoop::perform {
    include 'hadoop::install'
    include 'hadoop::config'
    include 'hadoop::service'

    Class['hadoop::install'] ->
    Class['hadoop::config'] ~>
    Class['hadoop::service'] ->
    Class['hadoop']
  }
}
