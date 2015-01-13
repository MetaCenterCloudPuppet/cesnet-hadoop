# == Class: hadoop
#
# Setup Hadoop Cluster. Security and Kerberos are supported.
#
# === Parameters
#
# [*hdfs_hostname*] (localhost)
#
#   Hadoop Filesystem Name Node machine.
#
# [*hdfs_hostname2*] (localhost)
#
#   Another Hadoop Filesystem Name Node machine. used for High Availability. This parameter will activate the HDFS HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html).
#
#   If you're converting existing Hadoop cluster without HA to cluster with HA, you need to initialize journalnodes yet:
#
#     hdfs namenode -initializeSharedEdits
#
#   Zookeepers are required for automatic transitions.
#
# [*yarn_hostname*] (localhost)
#
#   Yarn machine (with Resource Manager and Job History services).
#
# [*yarn_hostname2*] (localhost)
#
#   YARN resourcemanager second hostname for High Availability. This parameter will activate the YARN HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html](http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html).
#
#   Zookeepers are required.
#
# [*slaves*] (localhost)
#
#   Array of slave node hostnames.
#
# [*frontends*]
#
#   Array of frontend hostnames. Used *slaves* by default.
#
# [*cluster_name*] 'cluster'
#
#   Name of the cluster, used during initial formatting of HDFS. For non-HA configurations it may be undef.
#
# [*realm*] (required parameter, may be empty string)
#
#   Enable security and Kerberos realm to use. Empty string disables the security.
#   To enable security, there are required:
#
#   * installed Kerberos client (Debian: krb5-user/heimdal-clients; RedHat: krb5-workstation)
#   * configured Kerberos client (/etc/krb5.conf, /etc/krb5.keytab)
#   * /etc/security/keytab/dn.service.keytab (on data nodes)
#   * /etc/security/keytab/jhs.service.keytab (on job history node)
#   * /etc/security/keytab/nm.service.keytab (on node manager nodes)
#   * /etc/security/keytab/nn.service.keytab (on name nodes)
#   * /etc/security/keytab/rm.service.keytab (on resource manager node)
#
# It is used also as cookie domain (lowercased), if https is enabled. This may be overriden by http.authentication.cookie.domain in [*properties*].
#
# [*historyserver_hostname*] (undef)
#
#   History Server machine. Used *yarn_hostname* by default.
#
# [*nodemanager_hostnames*] (undef)
#
#   Array of Node Manager machines. Used *slaves* by default.
#
# [*datanode_hostnames*] (undef)
#
#   Array of Data Node machines. Used *slaves* by default.
#
# [*journalnode_hostnames*] (undef)
#
#   Array of HDFS Journal Node machines. Used in HDFS namenode HA.
#
# [*zookeeper_hostnames*] (undef)
#
#   Array of Zookeeper machines. Used in HDFS namenode HA for automatic failover and YARN resourcemanager state-store feature.
#
# With manual failover, the namenodes are always started in standby mode and one would need to be activated manually.
#
# [*hdfs_name_dirs*] (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])
#
#  Directory prefixes to store the metadata on the namenode.
#
# * name table (fsimage) and DFS data blocks
# * /${user.name}/dfs/namenode or /${user.name}/dfs/name suffix is always added
#  * If there is multiple directories, then the name table is replicated in all of the directories, for redundancy.
#  * All directories needs to be available to namenode work properly (==> good on mirrored raid)
#  * Crucial data (==> good to save at different physical locations)
#
# [*hdfs_data_dirs*] (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])
#
#  Directory prefixes to store the data on HDFS datanodes.
#  * /${user.name}/dfs/datanode suffix is always added
#  * If there is multiple directories, then data will be stored in all directories, typically on different devices.
#  When adding a new directory, you need to replicate the contents from some of the other ones. Or set dfs.namenode.name.dir.restore to true and create NEW\_DIR/hdfs/dfs/namenode with proper owners.
#
# [*hdfs_secondary_dirs*] undef
#
#   Directory prefixes to store metadata by secondary name nodes, if different from *hdfs_name_dirs*.
#
# [*hdfs_journal_dirs*] undef
#
#   Directory prefixes to store journal logs by journal name nodes, if different from *hdfs_name_dirs*.
#
# [*properties*] (see params.pp)
#
#   "Raw" properties for hadoop cluster. "::undef" will remove property from defaults, empty string sets empty value.
#
# [*descriptions*] (see params.pp)
#
#   Descriptions for the properties, just for cuteness.
#
# [*environments*] undef
#
#   Environment to set for all Hadoop daemons. Recommended is to increase java heap memory, if enough memory is available:
#   environments => ['export HADOOP\_HEAPSIZE=8192', 'export YARN\_HEAPSIZE=8192']
#
# Note: whether to use 'export' or not is system dependent (Debian 7/wheezy:
# yes, systemd-based distributions no).
#
# [*features*] ()
#
#   Enable additional features:
#
# * rmstore: resource manager recovery using state-store
#  * *hdfs*: store state on HDFS, this requires HDFS datanodes already running and /rmstore directory created ==> keep disabled on initial setup! Requires *hdfs_deployed* to be true
#  * *zookeeper*: store state on zookeepers; Requires *zookeeper_hostnames* specified. Warning: no authentication is used.
#  * *true*: select automatically zookeeper or hdfs ccording to *zookeeper_hostnames*
# * restarts: regular resource manager restarts (MIN HOUR MDAY MONTH WDAY); it shall never be restarted, but it may be needed for refreshing Kerberos tickets
# * krbrefresh: use and refresh Kerberos credential cache (MIN HOUR MDAY MONTH WDAY); beware there is a small race-condition during refresh
# * authorization - enable authorization and select authorization rules (permit, limit); recommended to try 'permit' rules first
# * yellowmanager - script in /usr/local to start/stop all daemons relevant for given node
# * multihome - enable properties required for multihome usage, you will need also add secondary IP addresses to *datanode_hostnames*
#
# [*acl*] undef
#
#   Set to true, if setfacl command is available and /etc/hadoop is on filesystem supporting POSIX ACL.
#   It is used only when https is enabled to set less open privileges on ssl-server.xml.
#
# [*alternatives*] (Debian: 'cluster', other: undef)
#
#   Use alternatives to switch configuration. It is used by Cloudera for example.
#
# [*https*] undef
#
#   Enable support for https.
#
#   Requires:
#
#   * enabled security (realm => ...)
#   * /etc/security/cacerts file (https\_cacerts parameter) - kept in the place, only permission changed, if needed
#   * /etc/security/server.keystore file (https\_keystore parameter) - copied for each daemon user
#   * /etc/security/http-auth-signature-secret file (any data, string or blob) - copied for each daemon user
#   * /etc/security/keytab/http.service.keytab - copied for each daemon user
#
# [*https_cacerts*] (/etc/security/cacerts)
#
#   CA certificates file.
#
# [*https_cacerts_password*] ('')
#
#   CA certificates keystore password.
#
# [*https_keystore*] (/etc/security/server.keystore)
#
#   Certificates keystore file.
#
# [*https_keystore_password*] ('changeit')
#
#   Certificates keystore file password.
#
# [*https_keystore_keypassword*] (undef)
#
#   Certificates keystore key password. If not specified, https\_keystore\_password is used.
#
# [*perform*] (false)
#
#   Launch all installation and setup here, from hadoop class.
#
# [*hdfs_deployed*] (true)
#
#   Perform also creating directories in HDFS. This action requires running namenode and datanodes, so it is recommended to set this to false during initial installation.
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
  $yarn_hostname2 = undef,
  $slaves = $params::slaves,
  $frontends = [],
  $cluster_name = $params::cluster_name,
  $realm,
  $authorization = $params::authorization,

  $historyserver_hostname = undef,
  $nodemanager_hostnames = undef,
  $datanode_hostnames = undef,
  $journalnode_hostnames = undef,
  $zookeeper_hostnames = undef,

  $hdfs_name_dirs = $params::hdfs_name_dirs,
  $hdfs_data_dirs = $params::hdfs_data_dirs,
  $hdfs_secondary_dirs = undef,
  $hdfs_journal_dirs = undef,
  $properties = undef,
  $descriptions = undef,
  $environments = undef,
  $features = $params::features,
  $acl = undef,
  $alternatives = $params::alternatives,
  $https = undef,
  $https_cacerts = $params::https_cacerts,
  $https_cacerts_password = $params::https_cacerts_password,
  $https_keystore = $params::https_keystore,
  $https_keystore_password = $params::https_keystore_password,
  $https_keystore_keypassword = $params::https_keystore_keypassword,
  $perform = $params::perform,
  $hdfs_deployed = $params::hdfs_deployed
) inherits hadoop::params {
  include 'stdlib'

  # detailed deployment bases on convenient parameters
  if $historyserver_hostname { $hs_hostname = $historyserver_hostname }
  else { $hs_hostname = $yarn_hostname }
  if $nodemanager_hostnames { $_nodemanager_hostnames = $nodemanager_hostnames }
  else { $_nodemanager_hostnames = $slaves }
  if $datanode_hostnames { $_datanode_hostnames = $datanode_hostnames }
  else { $_datanode_hostnames = $slaves }
  if $frontends { $frontend_hostnames = $frontends }
  else { $frontend_hostnames = $slaves }

  $_hdfs_name_dirs = $hdfs_name_dirs
  $_hdfs_data_dirs = $hdfs_data_dirs
  if !$hdfs_secondary_dirs { $_hdfs_secondary_dirs = $hadoop::hdfs_name_dirs }
  if !$hdfs_journal_dirs { $_hdfs_journal_dirs = $hadoop::hdfs_name_dirs }

  if $::fqdn == $hdfs_hostname or $::fqdn == $hdfs_hostname2 {
    $daemon_namenode = 1
    $mapred_user = 1
  }

  if $::fqdn == $yarn_hostname or $::fqdn == $yarn_hostname2{
    $daemon_resourcemanager = 1
  }

  if $::fqdn == $hs_hostname {
    $daemon_historyserver = 1
  }

  if member($_nodemanager_hostnames, $::fqdn) {
    $daemon_nodemanager = 1
  }

  if member($_datanode_hostnames, $::fqdn) {
    $daemon_datanode = 1
  }

  if $journalnode_hostnames and member($journalnode_hostnames, $::fqdn) {
    $daemon_journalnode = 1
  }

  if $zookeeper_hostnames and $daemon_namenode {
    $daemon_hdfs_zkfc = 1
  }

  if member($frontend_hostnames, $::fqdn) {
    $frontend = 1
  }

  if $zookeeper_hostnames {
    $zkquorum0 = join($zookeeper_hostnames, ':2181,')
    $zkquorum = "${zkquorum0}:2181"
  }

  if $datanode_hostnames {
    $slaves_hdfs = 'slaves-hdfs'
  } else {
    $slaves_hdfs = 'slaves'
  }
  if $nodemanager_hostnames {
    $slaves_yarn = 'slaves-yarn'
  } else {
    $slaves_yarn = 'slaves'
  }
  $dyn_properties = {
    'dfs.hosts' => "${hadoop::confdir}/${slaves_hdfs}",
    'dfs.hosts.exclude' => "${hadoop::confdir}/excludes",
    'fs.defaultFS' => "hdfs://${hdfs_hostname}:8020",
    'yarn.resourcemanager.hostname' => $yarn_hostname,
    'yarn.nodemanager.aux-services' => 'mapreduce_shuffle',
    'yarn.nodemanager.aux-services.mapreduce_shuffle.class' => 'org.apache.hadoop.mapred.ShuffleHandler',
    'yarn.resourcemanager.nodes.include-path' => "${hadoop::confdir}/${slaves_yarn}",
    'yarn.resourcemanager.nodes.exclude-path' => "${hadoop::confdir}/excludes",
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
RULE:[2:\$1;\$2@\$0](^[ndjs]n;.*@${realm}$)s/^.*$/hdfs/
RULE:[2:\$1;\$2@\$0](^[rn]m;.*@${realm}$)s/^.*$/yarn/
RULE:[2:\$1;\$2@\$0](^hbase;.*@${realm}$)s/^.*$/hbase/
RULE:[2:\$1;\$2@\$0](^hive;.*@${realm}$)s/^.*$/hive/
RULE:[2:\$1;\$2@\$0](^hue;.*@${realm}$)s/^.*$/hue/
RULE:[2:\$1;\$2@\$0](^tomcat;.*@${realm}$)s/^.*$/tomcat/
RULE:[2:\$1;\$2@\$0](^zookeeper;.*@${realm}$)s/^.*$/zookeeper/
RULE:[2:\$1;\$2@\$0](^HTTP;.*@${realm}$)s/^.*$/HTTP/
DEFAULT
",
      'dfs.datanode.address' => '0.0.0.0:1004',
      'dfs.datanode.http.address' => '0.0.0.0:1006',
      'dfs.block.access.token.enable' => true,
      'dfs.namenode.acls.enabled' => true,
      'dfs.namenode.kerberos.principal' => "nn/_HOST@${hadoop::realm}",
      'dfs.namenode.kerberos.https.principal' => "host/_HOST@${hadoop::realm}",
      'dfs.datanode.kerberos.principal' => "dn/_HOST@${hadoop::realm}",
      'dfs.datanode.kerberos.https.principal' => "host/_HOST@${hadoop::realm}",
      'dfs.journalnode.kerberos.principal' => "jn/_HOST@${hadoop::realm}",
      'dfs.encrypt.data.transfer' => false,
      'dfs.webhdfs.enabled' => true,
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

  if $hadoop::features['rmstore'] {
    if $hadoop::features['rmstore'] == 'hdfs' or ($hadoop::features['rmstore'] != 'zookeeper' and !$zookeeper_hostnames) {
      if $hadoop::hdfs_deployed {
        $rm_ss_properties = {
          'yarn.resourcemanager.recovery.enabled' => true,
          'yarn.resourcemanager.store.class' => 'org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore',
          # no hdfs://${hdfs_hostname}:8020 prefix - in case of HA HDFS
          'yarn.resourcemanager.fs.state-store.uri' => '/rmstore',
        }
      } else {
        $rm_ss_properties = {}
      }
    } elsif $hadoop::features['rmstore'] == 'zookeeper' or ($hadoop::features['rmstore'] != 'hdfs' and $zookeeper_hostnames) {
      $rm_ss_properties = {
        'yarn.resourcemanager.fs.state-store.uri' => '/rmstore',
        'yarn.resourcemanager.recovery.enabled' => true,
        'yarn.resourcemanager.store.class' => 'org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore',
      }
    }
  }

  if $hadoop::features['multihome'] {
    $mh_properties = {
      'hadoop.security.token.service.use_ip' => false,
      'yarn.resourcemanager.bind-host' => '0.0.0.0',
      'dfs.namenode.rpc-bind-host' => '0.0.0.0',
    }
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
        "dfs.namenode.https-address.${hadoop::cluster_name}.nn1" => "${hdfs_hostname}:50470",
        "dfs.namenode.https-address.${hadoop::cluster_name}.nn2" => "${hdfs_hostname2}:50470",
      }
    }
    $ha_journals = join($journalnode_hostnames, ':8485;')
    $ha_base_properties = {
      'dfs.nameservices' => "${hadoop::cluster_name}",
      "dfs.ha.namenodes.${hadoop::cluster_name}" => 'nn1,nn2',
      "dfs.namenode.rpc-address.${hadoop::cluster_name}.nn1" => "${hdfs_hostname}:8020",
      "dfs.namenode.rpc-address.${hadoop::cluster_name}.nn2" => "${hdfs_hostname2}:8020",
      "dfs.namenode.http-address.${hadoop::cluster_name}.nn1" => "${hdfs_hostname}:50070",
      "dfs.namenode.http-address.${hadoop::cluster_name}.nn2" => "${hdfs_hostname2}:50070",
      'dfs.namenode.shared.edits.dir' => "qjournal://${ha_journals}:8485/${hadoop::cluster_name}",
      "dfs.client.failover.proxy.provider.${hadoop::cluster_name}" => 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider',
      'dfs.ha.fencing.methods' => 'shell(/bin/true)',
      'fs.defaultFS' => "hdfs://${hadoop::cluster_name}",
    }

    $ha_hdfs_properties = merge($ha_base_properties, $ha_https_properties)
  }

  # High Availability of YARN
  if $yarn_hostname2 {
    $ha_yarn_properties = {
      'yarn.resourcemanager.cluster-id' => $hadoop::cluster_name,
      'yarn.resourcemanager.ha.enabled' => true,
      'yarn.resourcemanager.ha.rm-ids' => 'rm1,rm2',
      'yarn.resourcemanager.hostname.rm1' => "${yarn_hostname}",
      'yarn.resourcemanager.hostname.rm2' => "${yarn_hostname2}",
    }
  }
  $ha_properties = merge($ha_hdfs_properties, $ha_yarn_properties)

  # Automatic failover for HA HDFS
  if $zookeeper_hostnames and $hdfs_hostname2 {
    $zoo_hdfs_properties = {
      'dfs.ha.automatic-failover.enabled' => true,
      'ha.zookeeper.quorum' => "${zkquorum}",
    }
  }

  if $zookeeper_hostnames and ($yarn_hostname2 or $features['rmstore'] and $features['rmstore'] != 'hdfs') {
    $zoo_yarn_properties = {
      'yarn.resourcemanager.ha.automatic-failover.enabled' => true,
      # XXX: need limit, "host:${yarn_hostname}:rwcda" doesn't work (better proper auth anyway)
      'yarn.resourcemanager.zk-acl' => "world:anyone:rwcda",
      'yarn.resourcemanager.zk-address' => $zkquorum,
    }
  }
  $zoo_properties = merge($zoo_hdfs_properties, $zoo_yarn_properties)

  $props = merge($params::properties, $dyn_properties, $sec_properties, $auth_properties, $rm_ss_properties, $mh_properties, $https_properties, $ha_properties, $zoo_properties, $properties)
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
