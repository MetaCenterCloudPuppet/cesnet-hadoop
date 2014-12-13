# == Class: hadoop
#
# Setup Hadoop Cluster. Security and Kerberos are supported.
#
# === Parameters
#
# [*hdfs_hostname*] (localhost)
#   Hadoop Filesystem Name Node machine.
#
# [*hdfs_hostname2*] (localhost)
#   Hadoop Filesystem Name Node machine, used for High Availability. This parameter will activate the HDFS HA feature.
#
#   If you're converting existing Hadoop cluster without HA to cluster with HA, you need to initialize journalnodes yet:
#     hdfs namenode -initializeSharedEdits
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
# [*journalnode_hostnames*] (undef)
#   Array of HDFS Journal Node machines. Used in HDFS namenode HA.
#
# [*zookeeper_hostnames*] (undef)
#   Array of Zookeeper machines. Used in HDFS namenode HA for automatic failover.
#
# [*hdfs_name_dirs*] (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])
#  Directory prefixes to store the metadata on the namenode.
#  - name table (fsimage) and DFS data blocks
#  - /${user.name}/dfs/namenode or /${user.name}/dfs/name suffix is always added
#       - If there is multiple directories, then the name table is replicated in all of the directories, for redundancy.
#       - All directories needs to be available to namenode work properly (==> good on mirrored raid)
#       - Crucial data (==> good to save at different physical locations)
#
# [*hdfs_data_dirs*] (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])
#  Directory prefixes to store the data on HDFS datanodes.
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
# [*alternatives*] (Debian: 'cluster', other: undef)
#   Use alternatives to switch configuration. It is used by Cloudera for example.
#
# [*https*] (undef)
#   Support for https.
#
#   Requires:
#   * enabled security (realm => ...)
#   * /etc/security/cacerts file (https_cacerts parameter) - kept in the place, only permission changed, if needed
#   * /etc/security/server.keystore file (https_keystore parameter) - copied for each daemon user
#   * /etc/security/http-auth-signature-secret file (any data, string or blob) - copied for each daemon user
#   * /etc/security/keytab/http.service.keytab - copied for each daemon user
#
# [*https_cacerts*] (/etc/security/cacerts)
#   CA certificates file.
#
# [*https_cacerts_password*] ('')
#   CA certificates keystore password.
#
# [*https_keystore*] (/etc/security/server.keystore)
#   Certificates keystore file.
#
# [*https_keystore_password*] ('changeit')
#   Certificates keystore file password.
#
# [*https_keystore_keypassword*] (undef)
#   Certificates keystore key password. If not specified, https_keystore_password is used.
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
#  hdfs_name_dirs => [ "/var/lib/hadoop-hdfs", "/data2" ],
#  hdfs_data_dirs => [ "/var/lib/hadoop-hdfs", "/data2", "/data3", "/data4" ],
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
  $hdfs_hostname2 = undef,
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
  $journalnode_hostnames = undef,
  $zookeeper_hostnames = undef,

  $hdfs_name_dirs = $params::hdfs_name_dirs,
  $hdfs_data_dirs = $params::hdfs_data_dirs,
  $properties = undef,
  $descriptions = undef,
  $features = $params::features,
  $alternatives = $params::alternatives,
  $https = undef,
  $https_cacerts = $params::https_cacerts,
  $https_cacerts_password = $params::https_cacerts_password,
  $https_keystore = $params::https_keystore,
  $https_keystore_password = $params::https_keystore_password,
  $https_keystore_keypassword = $params::https_keystore_keypassword,
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

  if $::fqdn == $nn_hostname or $::fqdn == $hdfs_hostname2 {
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

  if member($journalnode_hostnames, $::fqdn) {
    $daemon_journalnode = 1
  }

  if $zookeeper_hostnames and $daemon_namenode {
    $daemon_hdfs_zkfc = 1
  }

  if member($frontend_hostnames, $::fqdn) {
    $frontend = 1
  }

  $dyn_properties = {
    'fs.defaultFS' => "hdfs://${nn_hostname}:8020",
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
      'dfs.journalnode.kerberos.principal' => "jn/_HOST@${hadoop::realm}",
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
      # no hdfs://${nn_hostname}:8020 prefix - in case of HA HDFS
      'yarn.resourcemanager.fs.state-store.uri' => "/rmstore",
    }
  } else {
    $rm_ss_properties = {}
  }
  if $hadoop::https {
    if !$hadoop::realm {
      err('Kerberos feature required for https support.')
    }
    $https_properties = {
      'hadoop.http.filter.initializers' => 'org.apache.hadoop.security.AuthenticationFilterInitializer',
      'hadoop.http.authentication.type' => 'kerberos',
      'hadoop.http.authentication.token.validity' => '36000',
      'hadoop.http.authentication.signature.secret.file' => '${user.home}/http-auth-signature-secret',
      'hadoop.http.authentication.cookie.domain' => downcase($hadoop::realm),
      'hadoop.http.authentication.simple.anonymous.allowed' => 'false',
      'hadoop.http.authentication.kerberos.principal' => "HTTP/_HOST@${hadoop::realm}",
      'hadoop.http.authentication.kerberos.keytab' => '${user.home}/hadoop.keytab',
      'dfs.http.policy' => 'HTTPS_ONLY',
      'dfs.journalnode.kerberos.internal.spnego.principal' => "HTTP/_HOST@${hadoop::realm}",
      'dfs.web.authentication.kerberos.keytab' => "${hadoop::hdfs_homedir}/hadoop.keytab",
      'mapreduce.jobhistory.http.policy' => 'HTTPS_ONLY',
      'yarn.http.policy' => 'HTTPS_ONLY',
    }
  } else {
    $https_properties = {}
  }

  # High Availability of HDFS
  if $hdfs_hostname2 {
    if ! $journalnode_hostnames {
      notice('only QJM HA implemented, journalnodes required for HDFS HA')
    }
    if ($https) {
      $ha_https_properties = {
        'dfs.namenode.https-address.mycluster.nn1' => "${hdfs_hostname}:50470",
        'dfs.namenode.https-address.mycluster.nn2' => "${hdfs_hostname2}:50470",
      }
    }
    $ha_journals = join($journalnode_hostnames, ':8485;')
    $ha_base_properties = {
      'dfs.nameservices' => 'mycluster',
      'dfs.ha.namenodes.mycluster' => 'nn1,nn2',
      'dfs.namenode.rpc-address.mycluster.nn1' => "${hdfs_hostname}:8020",
      'dfs.namenode.rpc-address.mycluster.nn2' => "${hdfs_hostname2}:8020",
      'dfs.namenode.http-address.mycluster.nn1' => "${hdfs_hostname}:50070",
      'dfs.namenode.http-address.mycluster.nn2' => "${hdfs_hostname2}:50070",
      'dfs.namenode.shared.edits.dir' => "qjournal://${ha_journals}:8485/mycluster",
      'dfs.client.failover.proxy.provider.mycluster' => 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider',
      'dfs.ha.fencing.methods' => 'shell(/bin/true)',
      'fs.defaultFS' => 'hdfs://mycluster',
    }

    $ha_properties = merge($ha_base_properties, $ha_https_properties)
  }
  # Automatic failover for HA HDFS
  if $zookeeper_hostnames {
    $zkquorum = join($zookeeper_hostnames, ':2181,')
    $zoo_properties = {
      'dfs.ha.automatic-failover.enabled' => true,
      'ha.zookeeper.quorum' => "${zkquorum}:2181",
    }
  }

  $props = merge($params::properties, $dyn_properties, $sec_properties, $auth_properties, $rm_ss_properties, $https_properties, $ha_properties, $zoo_properties, $properties)
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
