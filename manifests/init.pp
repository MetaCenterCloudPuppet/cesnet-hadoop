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
# [*hdfs_dirs*] (["/var/lib/hadoop-hdfs"])
#  Directory prefixes to store the data.
#    - namenode:
#  - name table (fsimage) and DFS data blocks
#  - /${user.name}/dfs/namenode suffix is always added
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
#   - rmstore: resource manager recovery using state-store
#   - rmrestart: regular resource manager restarts (MIN HOUR MDAY MONTH WDAY); it shall never be restarted, but it may be needed for refreshing Kerberos tickets
#   - krbrefresh: use and refresh Kerberos credential cache (MIN HOUR MDAY MONTH WDAY)
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
#  },
#}
#
class hadoop (
  $hdfs_hostname = $params::hdfs_hostname,
  $yarn_hostname = $params::yarn_hostname,
  $slaves = $params::slaves,
  $frontends = [],
  $cluster_name = $params::cluster_name,
  $realm,

  $namenode_hostname = undef,
  $resourcemanager_hostname = undef,
  $historyserver_hostname = undef,
  $nodemanager_hostnames = undef,
  $datanode_hostnames = undef,

  $hdfs_dirs = $params::hdfs_dirs,
  $properties = $params::properties,
  $descriptions = $params::descriptions,
  $features = $params::features,
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
    'yarn.resourcemanager.hostname' => "${rm_hostname}",
    'yarn.nodemanager.aux-services' => 'mapreduce_shuffle',
    'yarn.nodemanager.aux-services.mapreduce_shuffle.class' => 'org.apache.hadoop.mapred.ShuffleHandler',
  }
  if ($hadoop::realm) {
    $sec_properties = {
      'hadoop.security.authentication' => 'kerberos',
      'hadoop.security.authorization' => false,
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
      'dfs.namenode.kerberos.principal' => "nn/${nn_hostname}@${hadoop::realm}",
      'dfs.namenode.kerberos.https.principal' => "host/${nn_hostname}@${hadoop::realm}",
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
    $sec_descriptions = {
      'hadoop.security.authorization' => 'XXX:
Probably bug in Hadoop: nodemanagers can\'t authorize to resourcemanager.

org.apache.hadoop.yarn.exceptions.YarnRuntimeException: org.apache.hadoop.security.authorize.AuthorizationException: User nm/myriad2.zcu.cz@ZCU.CZ (auth:KERBEROS) is not authorized for protocol interface org.apache.hadoop.yarn.server.api.ResourceTrackerPB, expected client Kerberos principal is nm/myriad13.zcu.cz@ZCU.CZ',
      'hadoop.rcp.protection' => 'authentication, integrity, privacy',
      'hadoop.security.auth_to_local' => "give Kerberos principles proper groups (through mapping to local users)",
      'dfs.datanode.address' => 'different port with security enabled (original port 50010)',
      'dfs.datanode.http.address' => 'different port with security enabled (original port 50075)',
    }
  }
  if ($hadoop::features["rmstore"]) {
    $rm_ss_properties = {
      'yarn.resourcemanager.recovery.enabled' => true,
      'yarn.resourcemanager.store.class' => 'org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore',
      'yarn.resourcemanager.fs.state-store.uri' => "hdfs://${nn_hostname}:8020/rmstore",
      'dfs.webhdfs.enabled' => 'TODO: check, has been problems',
    }
  } else {
    $rm_ss_properties = {}
  }

  $props = merge($params::properties, $dyn_properties, $sec_properties, $rm_ss_properties, $properties)
  $descs = merge($params::descriptions, $sec_descriptions, $descriptions)

  include 'hadoop::install'
  include 'hadoop::config'
  include 'hadoop::service'

  Class['hadoop::install'] ->
  Class['hadoop::config'] ~>
  Class['hadoop::service'] ->
  Class['hadoop']

  Class['hadoop::install'] -> Class [ 'hadoop::common::slaves' ]

  # XXX: helper administrator script, move somewere else
  file { '/usr/local/bin/yellowelephant':
    mode    => '0755',
    alias   => 'yellowelephant',
    content => template('hadoop/yellowelephant.erb'),
    require => Class['hadoop::config'],
  }
}
