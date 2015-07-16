# == Class: hadoop
#
# Setup Hadoop Cluster. Security and Kerberos are supported.
#
# === Parameters
#
# ####`hdfs_hostname` $::fqdn
#
# Hadoop Filesystem Name Node machine.
#
# ####`hdfs_hostname2` undef
#
# Another Hadoop Filesystem Name Node machine. Used for High Availability. This parameter will activate the HDFS HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html).
#
# If you're converting existing Hadoop cluster without HA to cluster with HA, you need to initialize journalnodes yet:
#
#     hdfs namenode -initializeSharedEdits
#
# Zookeepers are required for automatic transitions.
#
# If Hadoop cluster is secured, it is recommended also secure Zookeeper. See *ha_credentials* and *ha_digest* parameters.
#
# ####`yarn_hostname` $::fqdn
#
# Yarn machine (with Resource Manager and Job History services).
#
# ####`yarn_hostname2` undef
#
# YARN resourcemanager second hostname for High Availability. This parameter will activate the YARN HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html](http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html).
#
# Zookeepers are required.
#
# ####`slaves` [$::fqdn]
#
# Array of slave node hostnames.
#
# ####`frontends` (*slaves*)
#
# Array of frontend hostnames. Used *slaves* by default.
#
# ####`cluster_name` 'cluster'
#
# Name of the cluster. Used during initial formatting of HDFS. For non-HA configurations it may be undef.
#
# ####`realm` (required parameter, may be empty string)
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
# It is used also as cookie domain (lowercased), if https is enabled. This may be overrided by http.authentication.cookie.domain in *properties*.
#
# ####`historyserver_hostname` undef
#
# History Server machine. Used *yarn_hostname* by default.
#
# ####`nodemanager_hostnames` undef
#
# Array of Node Manager machines. Used *slaves* by default.
#
# ####`datanode_hostnames` undef
#
# Array of Data Node machines. Used *slaves* by default.
#
# ####`journalnode_hostnames` undef
#
# Array of HDFS Journal Node machines. Used in HDFS namenode HA.
#
# ####`zookeeper_hostnames` undef
#
# Array of Zookeeper machines. Used in HDFS namenode HA for automatic failover and YARN resourcemanager state-store feature.
#
# Without zookeepers the manual failover is needed: the namenodes are always started in standby mode and one would need to be activated manually.
#
# ####`ha_credentials` undef
#
# With enabled high availability of HDFS in secured cluster it is recommended to secure also zookeeper. The value is in the form *USER:PASSWORD*.
#
# Set this to something like: **hdfs-zkfcs:PASSWORD**.
#
# ####`ha_digest` undef
#
# Digest version of *ha_credentials*. You can generate it this way:
#
#      java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper-*.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider hdfs-zkfcs:PASSWORD
#
# ####`hdfs_name_dirs` (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])
#
# Directory prefixes to store the metadata on the namenode.
#
# * directory for name table (fsimage)
# * /${user.name}/dfs/namenode or /${user.name}/dfs/name suffix is always added
#  * If there is multiple directories, then the name table is replicated in all of the directories, for redundancy.
#  * All directories needs to be available to namenode work properly (==> good on mirrored raid)
#  * Crucial data (==> good to save at different physical locations)
#
#  When adding a new directory, you will need to replicate the contents from some of the other ones. Or set dfs.namenode.name.dir.restore to true and create NEW\_DIR/hdfs/dfs/namenode with proper owners.
#
# ####`hdfs_data_dirs` (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])
#
# Directory prefixes to store the data on HDFS datanodes.
#
# * directory for DFS data blocks
#  * /${user.name}/dfs/datanode suffix is always added
#  * If there is multiple directories, then data will be stored in all directories, typically on different devices.
#
# ####`hdfs_secondary_dirs` undef
#
# Directory prefixes to store metadata by secondary name nodes, if different from *hdfs_name_dirs*.
#
# ####`hdfs_journal_dirs` undef
#
# Directory prefixes to store journal logs by journal name nodes, if different from *hdfs_name_dirs*.
#
# ####`properties` (see params.pp)
#
# "Raw" properties for hadoop cluster. "::undef" will remove property set automatically by this module, empty string sets empty value.
#
# ####`descriptions` (see params.pp)
#
# Descriptions for the properties. Just for cuteness.
#
# ####`environment` undef
#
# Environment to set for all Hadoop daemons.
#
#     environment => {'HADOOP_HEAPSIZE' => 4096, 'YARN_HEAPSIZE' => 4096}
#
# ####`features` (empty)
#
#  Enable additional features:
#
# * **rmstore**: resource manager recovery using state-store (YARN will depends on HDFS)
#  * *hdfs*: store state on HDFS, this requires HDFS datanodes already running and /rmstore directory created ==> keep disabled on initial setup! Requires *hdfs\_deployed* to be true
#  * *zookeeper*: store state on zookeepers; Requires *zookeeper_hostnames* specified. Warning: no authentication is used.
#  * *true*: select automatically zookeeper or hdfs according to *zookeeper_hostnames*
# * **restarts**: regular resource manager restarts (MIN HOUR MDAY MONTH WDAY); it shall never be restarted, but it may be needed for refreshing Kerberos tickets
# * **krbrefresh**: use and refresh Kerberos credential cache (MIN HOUR MDAY MONTH WDAY); beware there is a small race-condition during refresh
# * **yellowmanager**: script in /usr/local to start/stop all daemons relevant for given node
# * **multihome**: enable properties required for multihome usage, you will need also add secondary IP addresses to *datanode_hostnames*
# * **aggregation**: enable YARN log aggregation (recommended, YARN will depend on HDFS)
#
# Recommended features to enable are: **rmstore**, **aggregation** and probably **multihome**.
#
# ####`compress_enable` true
#
# Enable compression of intermediate files by snappy codec. This will set following properties:
#
# * *mapred.compress.map.output*: true
# * *mapred.map.output.compression.codec*: "org.apache.hadoop.io.compress.SnappyCodec"
#
# ####`acl` undef
#
# Set to true, if setfacl command is available and /etc/hadoop is on filesystem supporting POSIX ACL.
# It is used only when https is enabled to set less open privileges on ssl-server.xml.
#
# ####`alternatives` (Debian: 'cluster', other: undef)
#
# Use alternatives to switch configuration. Use it only when supported (like with Cloudera for example).
#
# ####`authorization` (empty)
#
# Hadoop service level authorization ACLs. Authorizations are enabled and predefined rule set and/or particular properties can be specified.
#
# Each ACL is in the form of: (wildcard "\*" allowed)
#
# * "USER1,USER2,... GROUP1,GROUP2"
# * "USER1,USER2,..."
# * " GROUP1,GROUP2,..." (notice the space character)
#
# These properties are available:
#
# * *rules* (**limit**, **permit**, **false**): predefined ACL sets from cesnet-hadoop puppet module
# * *security.service.authorization.default.acl*: default ACL
# * *security.client.datanode.protocol.acl*
# * *security.client.protocol.acl*
# * *security.datanode.protocol.acl*
# * *security.inter.datanode.protocol.acl*
# * *security.namenode.protocol.acl*
# * *security.admin.operations.protocol.acl*
# * *security.refresh.usertogroups.mappings.protocol.acl*
# * *security.refresh.policy.protocol.acl*
# * *security.ha.service.protocol.acl*
# * *security.zkfc.protocol.acl*
# * *security.qjournal.service.protocol.acl*
# * *security.mrhs.client.protocol.acl*
# * *security.resourcetracker.protocol.acl*
# * *security.resourcemanager-administration.protocol.acl*
# * *security.applicationclient.protocol.acl*
# * *security.applicationmaster.protocol.acl*
# * *security.containermanagement.protocol.acl*
# * *security.resourcelocalizer.protocol.acl*
# * *security.job.task.protocol.acl*
# * *security.job.client.protocol.acl*
# * ... and everything with *.blocked* suffix
#
# ACL set: **limit**: policy tuned with minimal set of permissions:
#
# * *security.datanode.protocol.acl* => ' hadoop'
# * *security.inter.datanode.protocol.acl* => ' hadoop'
# * *security.namenode.protocol.acl* => 'hdfs,nn,sn'
# * *security.admin.operations.protocol.acl* => ' hadoop'
# * *security.refresh.usertogroups.mappings.protocol.acl* => ' hadoop'
# * *security.refresh.policy.protocol.acl* => ' hadoop'
# * *security.ha.service.protocol.acl* => ' hadoop'
# * *security.zkfc.protocol.acl* => ' hadoop'
# * *security.qjournal.service.protocol.acl* => ' hadoop'
# * *security.resourcetracker.protocol.acl* => 'yarn,nm,rm'
# * *security.resourcemanager-administration.protocol.acl* => ' hadoop',
# * *security.applicationmaster.protocol.acl* => '\*',
# * *security.containermanagement.protocol.acl* => '\*',
# * *security.resourcelocalizer.protocol.acl* => '\*',
# * *security.job.task.protocol.acl* => '\*',
#
# ACL set: **permit** defines this policy (it's default):
#
# * *security.service.authorization.default.acl* => '\*'
#
# See also [Service Level Authorization Hadoop documentation](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ServiceLevelAuth.html).
#
# You can use use **limit** rules. For more strict settings you can define *security.service.authorization.default.acl* to something different from '\*':
#
#     authorization => {
#       'rules' => 'limit',
#       'security.service.authorization.default.acl' => ' hadoop,hbase,hive,spark,users',
#     }
#
# Note: Beware *...acl.blocked* are not used if the *....acl* counterpart is defined.
#
# Note 2: If not using wildcards in permit rules, you should enable access also for Hadoop additions (as seen in example).
#
# ####`https` undef
#
# Enable support for https.
#
# Requires:
#
# * enabled security (non-empty *realm*)
# * /etc/security/cacerts file (https\_cacerts parameter) - kept in the place, only permission changed, if needed
# * /etc/security/server.keystore file (https\_keystore parameter) - copied for each daemon user
# * /etc/security/http-auth-signature-secret file (any data, string or blob) - copied for each daemon user
# * /etc/security/keytab/http.service.keytab - copied for each daemon user
#
# ####`https_cacerts` '/etc/security/cacerts'
#
# CA certificates file.
#
# ####`https_cacerts_password` ''
#
# CA certificates keystore password.
#
# ####`https_keystore` '/etc/security/server.keystore'
#
# Certificates keystore file.
#
# ####`https_keystore_password` 'changeit'
#
# Certificates keystore file password.
#
# ####`https_keystore_keypassword` undef
#
# Certificates keystore key password. If not specified, https\_keystore\_password is used.
#
# ####`https_keytab` '/etc/security/keytab/http.service.keytab'
#
# Keytab file for HTTPS. It will be copied for each daemon user and according permissions and properties set.
#
# ####`min_uid` (autodetect)
#
# Minimal permitted UID of Hadoop users. Used in Linux containers, when security is enabled.
#
# ####`perform` false
#
# Launch all installation and setup here, from hadoop class.
#
# ####`hdfs_deployed` true
#
# Perform also actions requiring working HDFS (namenode + enough datanodes): enabling RM HDFS state-store feature (if enabled), and starting MapReduce History Server. This action requires running namenode and datanodes, so you can set this to *false* during initial installation.
#
# ####`zookeeper_deployed` true
#
# Perform also actions requiring working zookeeper and journal nodes: when enabled, launch ZKFC daemons and secondary namenode. You can set this to *false* during initial installation when High Availability is enabled.
#
# ####`keytab_namenode` '/etc/security/keytab/nn.service.keytab'
#
# Keytab file for HDFS Name Node. This will set also property *dfs.namenode.keytab.file*, if not specified directly.
#
# ####`keytab_datanode` '/etc/security/keytab/dn.service.keytab'
#
# Keytab file for HDFS Data Node. This will set also property *dfs.datanode.keytab.file*, if not specified directly.
#
# ####`keytab_jobhistory` '/etc/security/keytab/jhs.service.keytab'
#
# Keytab file for Map Reduce Job History Server. This will set also property *mapreduce.jobhistory.keytab*, if not specified directly.
#
# ####`keytab_journalnode` '/etc/security/keytab/jn.service.keytab'
#
# Keytab file for HDFS Data Node. This will set also property *dfs.journalnode.keytab.file*, if not specified directly.
#
# ####`keytab_resourcemanager` '/etc/security/keytab/rm.service.keytab'
#
# Keytab file for YARN Resource Manager. This will set also property *yarn.resourcemanager.keytab*, if not specified directly.
#
# ####`keytab_nodemanager` '/etc/security/keytab/nm.service.keytab'
#
# Keytab file for YARN Node Manager. This will set also property *yarn.nodemanager.keytab*, if not specified directly.
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
#    yellowmanager => true,
#  },
#  authorization => {
#    'rules' => 'limit',
#  }
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

  $historyserver_hostname = undef,
  $nodemanager_hostnames = undef,
  $datanode_hostnames = undef,
  $journalnode_hostnames = undef,
  $zookeeper_hostnames = undef,

  $ha_credentials = undef,
  $ha_digest = undef,
  $hdfs_name_dirs = $params::hdfs_name_dirs,
  $hdfs_data_dirs = $params::hdfs_data_dirs,
  $hdfs_secondary_dirs = undef,
  $hdfs_journal_dirs = undef,
  $properties = undef,
  $descriptions = undef,
  $environment = undef,
  $features = $params::features,
  $compress_enable = true,
  $acl = undef,
  $alternatives = $params::alternatives,
  $authorization = undef,
  $https = undef,
  $https_cacerts = $params::https_cacerts,
  $https_cacerts_password = $params::https_cacerts_password,
  $https_keystore = $params::https_keystore,
  $https_keystore_password = $params::https_keystore_password,
  $https_keytab = $params::https_keytab,
  $https_keystore_keypassword = $params::https_keystore_keypassword,
  $min_uid = $params::uid_min,
  $perform = $params::perform,

  $hdfs_deployed = $params::hdfs_deployed,
  $zookeeper_deployed = $params::zookeeper_deployed,

  $keytab_namenode = $params::keytab_namenode,
  $keytab_datanode = $params::keytab_datanode,
  $keytab_jobhistory = $params::keytab_jobhistory,
  $keytab_journalnode = $params::keytab_journalnode,
  $keytab_resourcemanager = $params::keytab_resourcemanager,
  $keytab_nodemanager = $params::keytab_nodemanager,
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
    $daemon_namenode = true
    $mapred_user = true
  } else {
    $daemon_namenode = false
    $mapred_user = false
  }

  if $::fqdn == $yarn_hostname or $::fqdn == $yarn_hostname2{
    $daemon_resourcemanager = true
  } else {
    $daemon_resourcemanager = false
  }

  if $::fqdn == $hs_hostname {
    $daemon_historyserver = true
  } else {
    $daemon_historyserver = false
  }

  if member($_nodemanager_hostnames, $::fqdn) {
    $daemon_nodemanager = true
  } else {
    $daemon_nodemanager = false
  }

  if member($_datanode_hostnames, $::fqdn) {
    $daemon_datanode = true
  } else {
    $daemon_datanode = false
  }

  if $journalnode_hostnames and member($journalnode_hostnames, $::fqdn) {
    $daemon_journalnode = true
  } else {
    $daemon_journalnode = false
  }

  if $zookeeper_hostnames and $daemon_namenode {
    $daemon_hdfs_zkfc = true
  } else {
    $daemon_hdfs_zkfc = false
  }

  if member($frontend_hostnames, $::fqdn) {
    $frontend = true
  } else {
    $frontend = false
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
    'yarn.nodemanager.log-dirs' => 'file:///var/log/hadoop-yarn/containers',
    'yarn.resourcemanager.nodes.include-path' => "${hadoop::confdir}/${slaves_yarn}",
    'yarn.resourcemanager.nodes.exclude-path' => "${hadoop::confdir}/excludes",
    'mapreduce.framework.name' => 'yarn',
    'mapreduce.jobhistory.address' => "${hs_hostname}:10020",
    'mapreduce.jobhistory.webapps.address' => "${hs_hostname}:19888",
    'mapreduce.task.tmp.dir' => '/var/cache/hadoop-mapreduce/${user.name}/tasks',
  }
  if $hadoop::realm and $hadoop::realm != '' {
    $sec_properties = {
      'hadoop.security.authentication' => 'kerberos',
      'hadoop.rcp.protection' => 'integrity',
      # update also "Auth to local mapping" chapter
      'hadoop.security.auth_to_local' => "
RULE:[2:\$1;\$2@\$0](^jhs;.*@${realm}$)s/^.*$/mapred/
RULE:[2:\$1;\$2@\$0](^[ndjs]n;.*@${realm}$)s/^.*$/hdfs/
RULE:[2:\$1;\$2@\$0](^[rn]m;.*@${realm}$)s/^.*$/yarn/
RULE:[2:\$1;\$2@\$0](^hbase;.*@${realm}$)s/^.*$/hbase/
RULE:[2:\$1;\$2@\$0](^hive;.*@${realm}$)s/^.*$/hive/
RULE:[2:\$1;\$2@\$0](^hue;.*@${realm}$)s/^.*$/hue/
RULE:[2:\$1;\$2@\$0](^spark;.*@${realm}$)s/^.*$/spark/
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
      'dfs.namenode.keytab.file' => $keytab_namenode,
      'dfs.datanode.kerberos.principal' => "dn/_HOST@${hadoop::realm}",
      'dfs.datanode.kerberos.https.principal' => "host/_HOST@${hadoop::realm}",
      'dfs.datanode.keytab.file' => $keytab_datanode,
      'dfs.journalnode.kerberos.principal' => "jn/_HOST@${hadoop::realm}",
      'dfs.journalnode.keytab.file' => $keytab_journalnode,
      'dfs.encrypt.data.transfer' => false,
      'dfs.webhdfs.enabled' => true,
      'dfs.web.authentication.kerberos.principal' => "HTTP/_HOST@${hadoop::realm}",
      'mapreduce.jobhistory.keytab' => $keytab_jobhistory,
      'mapreduce.jobhistory.principal' => "jhs/_HOST@${hadoop::realm}",
      'yarn.resourcemanager.keytab' => $keytab_resourcemanager,
      'yarn.nodemanager.keytab' => $keytab_nodemanager,
      'yarn.resourcemanager.principal' => "rm/_HOST@${hadoop::realm}",
      'yarn.nodemanager.principal' => "nm/_HOST@${hadoop::realm}",
      'yarn.nodemanager.container-executor.class' => 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor',
      'yarn.nodemanager.linux-container-executor.group' => 'hadoop',
    }
  } else {
    $sec_properties = undef
  }
  if $hadoop::authorization {
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
    } else {
        $rm_ss_properties = undef
    }
  } else {
    $rm_ss_properties = undef
  }

  if $hadoop::features['multihome'] {
    $mh_properties = {
      'hadoop.security.token.service.use_ip' => false,
      'yarn.resourcemanager.bind-host' => '0.0.0.0',
      'dfs.namenode.rpc-bind-host' => '0.0.0.0',
    }
  } else {
    $mh_properties = undef
  }

  if $hadoop::features['aggregation'] {
    $agg_properties = {
      'yarn.log-aggregation-enable' => true,
      'yarn.nodemanager.remote-app-log-dir' => '/var/log/hadoop-yarn/apps',
    }
  } else {
    $agg_properties = undef
  }

  if $hadoop::compress_enable {
    $compress_properties = {
      'mapreduce.map.output.compress' => true,
      'mapreduce.map.output.compress.codec' => 'org.apache.hadoop.io.compress.SnappyCodec',
    }
  } else {
    $compress_properties = undef
  }

  if $hadoop::https {
    if !$hadoop::realm or $hadoop::realm == '' {
      err('Kerberos feature required for https support.')
    }
    $https_properties = {
      'hadoop.http.filter.initializers' => 'org.apache.hadoop.security.AuthenticationFilterInitializer',
      'hadoop.http.authentication.type' => 'kerberos',
      'hadoop.http.authentication.token.validity' => '36000',
      'hadoop.http.authentication.signature.secret.file' => '${user.home}/http-auth-signature-secret',
      'hadoop.http.authentication.cookie.domain' => downcase($hadoop::realm),
      'hadoop.http.authentication.simple.anonymous.allowed' => false,
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
    if !$hadoop::realm or $hadoop::realm == '' {
      if !$hadoop::ha_credentials or !$hadoop::ha_digest {
        warning('ha_credentials and ha_digest parameters are recommended in secured HA cluster')
      }
    }
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
      'dfs.nameservices' => $hadoop::cluster_name,
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

    if $hadoop::ha_credentials and $hadoop::ha_diest {
      $ha_credentials_properties = {
        'ha.zookeeper.auth' => "@${hadoop::confdir}/zk-auth.txt",
        'ha.zookeeper.acl' => "@${hadoop::confdir}/zk-acl.txt",
      }
    } else {
      $ha_credentials_properties = undef
    }

    $ha_hdfs_properties = merge($ha_base_properties, $ha_https_properties, $ha_credentials_properties)
  } else {
    $ha_hdfs_properties = undef
  }

  # High Availability of YARN
  if $yarn_hostname2 {
    $ha_yarn_properties = {
      'yarn.resourcemanager.cluster-id' => $hadoop::cluster_name,
      'yarn.resourcemanager.ha.enabled' => true,
      'yarn.resourcemanager.ha.rm-ids' => 'rm1,rm2',
      'yarn.resourcemanager.hostname.rm1' => $yarn_hostname,
      'yarn.resourcemanager.hostname.rm2' => $yarn_hostname2,
    }
  } else {
    $ha_yarn_properties = undef
  }
  $ha_properties = merge($ha_hdfs_properties, $ha_yarn_properties)

  # Automatic failover for HA HDFS
  if $zookeeper_hostnames and $hdfs_hostname2 {
    $zoo_hdfs_properties = {
      'dfs.ha.automatic-failover.enabled' => true,
      'ha.zookeeper.quorum' => $zkquorum,
    }
  } else {
    $zoo_hdfs_properties = undef
  }

  if $zookeeper_hostnames and ($yarn_hostname2 or $features['rmstore'] and $features['rmstore'] != 'hdfs') {
    $zoo_yarn_properties = {
      'yarn.resourcemanager.ha.automatic-failover.enabled' => true,
      # XXX: need limit, "host:${yarn_hostname}:rwcda" doesn't work (better proper auth anyway)
      'yarn.resourcemanager.zk-acl' => 'world:anyone:rwcda',
      'yarn.resourcemanager.zk-address' => $zkquorum,
    }
  } else {
    $zoo_yarn_properties = undef
  }
  $zoo_properties = merge($zoo_hdfs_properties, $zoo_yarn_properties)

  if $authorization {
    case $authorization['rules'] {
      'limit', true: {
        $preset_authorization = {
          'security.datanode.protocol.acl' => ' hadoop',
          'security.inter.datanode.protocol.acl' => ' hadoop',
          'security.namenode.protocol.acl' => 'hdfs,nn,sn',
          'security.admin.operations.protocol.acl' => ' hadoop',
          'security.refresh.usertogroups.mappings.protocol.acl' => ' hadoop',
          'security.refresh.policy.protocol.acl' => ' hadoop',
          'security.ha.service.protocol.acl' => ' hadoop',
          'security.zkfc.protocol.acl' => ' hadoop',
          'security.qjournal.service.protocol.acl' => ' hadoop',
          'security.resourcetracker.protocol.acl' => 'yarn,nm,rm',
          'security.resourcemanager-administration.protocol.acl' => ' hadoop',
          'security.applicationmaster.protocol.acl' => '*',
          'security.containermanagement.protocol.acl' => '*',
          'security.resourcelocalizer.protocol.acl' => '*',
          'security.job.task.protocol.acl' => '*',
        }
      }
      'permit': {
        $preset_authorization = {
          'security.service.authorization.default.acl' => '*',
        }
      }
      'permit', default: {
        $preset_authorization = {}
      }
    }
  } else {
    $preset_authorization = {}
  }

  $props = merge($params::properties, $dyn_properties, $sec_properties, $auth_properties, $rm_ss_properties, $mh_properties, $agg_properties, $compress_properties, $https_properties, $ha_properties, $zoo_properties, $properties)
  $descs = merge($params::descriptions, $descriptions)

  $_authorization = merge($preset_authorization, delete($authorization, 'rules'))

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
