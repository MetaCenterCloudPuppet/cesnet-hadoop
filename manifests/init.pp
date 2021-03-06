# == Class: hadoop
#
# Main configuration class.
#
class hadoop (
  $defaultFS = undef,
  $hdfs_hostname = undef,
  $hdfs_hostname2 = undef,
  $yarn_hostname = undef,
  $yarn_hostname2 = undef,
  $slaves = [$::fqdn],
  $frontends = [],

  $historyserver_hostname = undef,
  $httpfs_hostnames = [],
  $hue_hostnames = [],
  $nodemanager_hostnames = undef,
  $datanode_hostnames = undef,
  $journalnode_hostnames = undef,
  $nfs_hostnames = [],
  $oozie_hostnames = [],
  $zookeeper_hostnames = undef,

  $cluster_name = $::hadoop::params::cluster_name,
  $ha_credentials = undef,
  $ha_digest = undef,
  $hdfs_name_dirs = $::hadoop::params::hdfs_name_dirs,
  $hdfs_data_dirs = $::hadoop::params::hdfs_data_dirs,
  $hdfs_secondary_dirs = undef,
  $hdfs_journal_dirs = undef,
  $hdfs_port_namenode = undef,
  $hdfs_port_namenode_http = undef,
  $hdfs_port_namenode_https = undef,
  $properties = undef,
  $descriptions = undef,
  $environment = undef,
  $features = $::hadoop::params::features,
  $compress_enable = true,
  $acl = undef,
  $alternatives = '::default',
  $alternatives_httpfs = '::default',
  $authorization = undef,
  $https = undef,
  $https_cacerts = $::hadoop::params::https_cacerts,
  $https_cacerts_password = $::hadoop::params::https_cacerts_password,
  $https_keystore = $::hadoop::params::https_keystore,
  $https_keystore_password = $::hadoop::params::https_keystore_password,
  $https_keytab = $::hadoop::params::https_keytab,
  $https_keystore_keypassword = $::hadoop::params::https_keystore_keypassword,
  $impala_enable = true,
  $min_uid = $::hadoop::params::uid_min,
  $nfs_dumpdir = $::hadoop::params::nfs_dumpdir,
  $nfs_exports = "${::fqdn} rw",
  $nfs_mount = $::hadoop::params::nfs_mount,
  $nfs_mount_options = undef,
  $nfs_proxy_user = undef,
  $nfs_system_user = $::hadoop::params::nfs_system_user,
  $perform = $::hadoop::params::perform,
  $realm = '',
  $scratch_dir = undef,
  $version = 3,

  $hdfs_deployed = $::hadoop::params::hdfs_deployed,
  $zookeeper_deployed = $::hadoop::params::zookeeper_deployed,

  $confdir = $::hadoop::params::confdir,
  $confdir_httpfs = $::hadoop::params::confdir_httpfs,

  $keytab_namenode = $::hadoop::params::keytab_namenode,
  $keytab_datanode = $::hadoop::params::keytab_datanode,
  $keytab_httpfs = $::hadoop::params::keytab_httpfs,
  $keytab_jobhistory = $::hadoop::params::keytab_jobhistory,
  $keytab_journalnode = $::hadoop::params::keytab_journalnode,
  $keytab_resourcemanager = $::hadoop::params::keytab_resourcemanager,
  $keytab_nodemanager = $::hadoop::params::keytab_nodemanager,
  $keytab_nfs = $::hadoop::params::keytab_nfs,
  $keytab_hdfs_admin = '::default',

  $principal_hdfs_admin = '::default',
  $principal_namenode = '::default',
) inherits hadoop::params {
  include ::stdlib

  case "${::hadoop::version}." {
    /^2(\.)?/: {
      $default_hdfs_port_namenode = '8020'
      $default_hdfs_port_namenode_http = '50070'
      $default_hdfs_port_namenode_https = '50470'
    }
    default: {
      # changed back from 9820 to 8020 in Hadoop 3.0.1
      $default_hdfs_port_namenode = '8020'
      $default_hdfs_port_namenode_http = '9870'
      $default_hdfs_port_namenode_https = '9871'
    }
  }
  $_hdfs_port_namenode = pick($hdfs_port_namenode, $default_hdfs_port_namenode)
  $_hdfs_port_namenode_http = pick($hdfs_port_namenode_http, $default_hdfs_port_namenode_http)
  $_hdfs_port_namenode_https = pick($hdfs_port_namenode_https, $default_hdfs_port_namenode_https)

  if (!$defaultFS and (!$hdfs_hostname or $hdfs_hostname == '')) {
    err('Either hdfs_hostname or defaultFS parameter needed')
  }
  if ($defaultFS) {
    $_defaultFS = $defaultFS
  } elsif ($hdfs_hostname2) {
    $_defaultFS = "hdfs://${hadoop::cluster_name}"
  } else {
    $_defaultFS = "hdfs://${hdfs_hostname}:${_hdfs_port_namenode}"
  }

  $hdfs_enable = $hdfs_hostname and $hdfs_hostname != ''
  $yarn_enable = $yarn_hostname and $yarn_hostname != ''

  # detailed deployment bases on convenient parameters
  if $historyserver_hostname { $hs_hostname = $historyserver_hostname }
  else { $hs_hostname = $yarn_hostname }
  if $yarn_enable {
    if $nodemanager_hostnames { $_nodemanager_hostnames = $nodemanager_hostnames }
    else { $_nodemanager_hostnames = $slaves }
  } else {
    $_nodemanager_hostnames = []
  }
  if $hdfs_enable {
    if $datanode_hostnames { $_datanode_hostnames = $datanode_hostnames }
    else { $_datanode_hostnames = $slaves }
  } else {
    $_datanode_hostnames = []
  }
  if $frontends { $frontend_hostnames = $frontends }
  else { $frontend_hostnames = $slaves }

  $_hdfs_name_dirs = $hdfs_name_dirs
  $_hdfs_data_storages = hadoop_storages($hdfs_data_dirs)
  if !$hdfs_secondary_dirs { $_hdfs_secondary_dirs = $hadoop::hdfs_name_dirs }
  if !$hdfs_journal_dirs { $_hdfs_journal_dirs = $hadoop::hdfs_name_dirs }

  if !$nfs_proxy_user {
    if $hadoop::realm and $hadoop::realm != '' {
      $_nfs_proxy_user = 'nfs'
    } else {
      $_nfs_proxy_user = $nfs_system_user
    }
  }

  if $keytab_hdfs_admin == '::default' {
    $_keytab_hdfs_admin = $keytab_namenode
  } else {
    $_keytab_hdfs_admin = $keytab_hdfs_admin
  }

  if $principal_hdfs_admin == '::default' {
    $_principal_hdfs_admin = "nn/${::fqdn}@${hadoop::realm}"
  } else {
    $_principal_hdfs_admin = $principal_hdfs_admin
  }

  if $principal_namenode == '::default' {
    $_principal_namenode = "nn/_HOST@${hadoop::realm}"
  } else {
    $_principal_namenode = $principal_namenode
  }

  if $hdfs_enable and ($::fqdn == $hdfs_hostname or $::fqdn == $hdfs_hostname2) {
    $daemon_namenode = true
    $mapred_user = true
  } else {
    $daemon_namenode = false
    $mapred_user = false
  }

  if $yarn_enable and ($::fqdn == $yarn_hostname or $::fqdn == $yarn_hostname2) {
    $daemon_resourcemanager = true
  } else {
    $daemon_resourcemanager = false
  }

  if $yarn_enable and $::fqdn == $hs_hostname {
    $daemon_historyserver = true
  } else {
    $daemon_historyserver = false
  }

  if $yarn_enable and member($_nodemanager_hostnames, $::fqdn) {
    $daemon_nodemanager = true
  } else {
    $daemon_nodemanager = false
  }

  if $hdfs_enable and member($_datanode_hostnames, $::fqdn) {
    $daemon_datanode = true
  } else {
    $daemon_datanode = false
  }

  if $hdfs_enable and $journalnode_hostnames and member($journalnode_hostnames, $::fqdn) {
    $daemon_journalnode = true
  } else {
    $daemon_journalnode = false
  }

  if $hdfs_hostname2 {
    if $daemon_namenode and $zookeeper_hostnames and (!$properties or !has_key($properties, 'dfs.ha.automatic-failover.enabled') or $properties['dfs.ha.automatic-failover.enabled']) {
      $daemon_hdfs_zkfc = true
    } else {
      $daemon_hdfs_zkfc = false
    }
  } else {
    $daemon_hdfs_zkfc = false
  }

  if member($httpfs_hostnames, $::fqdn) {
    $daemon_httpfs = true
  } else {
    $daemon_httpfs = false
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
  if member($nfs_hostnames, $::fqdn) {
    $nfs = true
  } else {
    $nfs = false
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
    'fs.defaultFS' => $_defaultFS,
  }
  if $hdfs_enable {
    $hdfs_properties = {
      'dfs.datanode.hdfs-blocks-metadata.enabled' => true,
      'dfs.hosts' => "${hadoop::confdir}/${slaves_hdfs}",
      'dfs.hosts.exclude' => "${hadoop::confdir}/excludes",
    }
  } else {
    $hdfs_properties = undef
  }
  if $yarn_enable {
    $yarn_properties = {
      'mapreduce.framework.name' => 'yarn',
      'mapreduce.jobhistory.address' => "${hs_hostname}:10020",
      'mapreduce.task.tmp.dir' => '/var/cache/hadoop-mapreduce/${user.name}/tasks',
      # this is required since Hadoop 3.x
      'mapreduce.map.env' => 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/hadoop/lib/native',
      # this is required since Hadoop 3.x
      'mapreduce.reduce.env' => 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/hadoop/lib/native',
      'yarn.resourcemanager.hostname' => $yarn_hostname,
      'yarn.nodemanager.aux-services' => 'mapreduce_shuffle',
      'yarn.nodemanager.aux-services.mapreduce_shuffle.class' => 'org.apache.hadoop.mapred.ShuffleHandler',
      'yarn.resourcemanager.nodes.include-path' => "${hadoop::confdir}/${slaves_yarn}",
      'yarn.resourcemanager.nodes.exclude-path' => "${hadoop::confdir}/excludes",
    }
  } else {
    $yarn_properties = undef
  }
  # update also "Auth to local mapping" chapter
  $auth_rules_default = "
RULE:[2:\$1;\$2@\$0](^jhs;.*@${realm}$)s/^.*$/mapred/
RULE:[2:\$1;\$2@\$0](^[ndjs]n;.*@${realm}$)s/^.*$/hdfs/
RULE:[2:\$1;\$2@\$0](^nfs;.*@${realm}$)s/^.*$/${_nfs_proxy_user}/
RULE:[2:\$1;\$2@\$0](^[rn]m;.*@${realm}$)s/^.*$/yarn/
RULE:[2:\$1;\$2@\$0](^hbase;.*@${realm}$)s/^.*$/hbase/
RULE:[2:\$1;\$2@\$0](^hive;.*@${realm}$)s/^.*$/hive/
RULE:[2:\$1;\$2@\$0](^hue;.*@${realm}$)s/^.*$/hue/
RULE:[2:\$1;\$2@\$0](^httpfs;.*@${realm}$)s/^.*$/httpfs/
RULE:[2:\$1;\$2@\$0](^impala;.*@${realm}$)s/^.*$/impala/
RULE:[2:\$1;\$2@\$0](^oozie;.*@${realm}$)s/^.*$/oozie/
RULE:[2:\$1;\$2@\$0](^solr;.*@${realm}$)s/^.*$/solr/
RULE:[2:\$1;\$2@\$0](^spark;.*@${realm}$)s/^.*$/spark/
RULE:[2:\$1;\$2@\$0](^sqoop;.*@${realm}$)s/^.*$/sqoop/
RULE:[2:\$1;\$2@\$0](^tomcat;.*@${realm}$)s/^.*$/tomcat/
RULE:[2:\$1;\$2@\$0](^zookeeper;.*@${realm}$)s/^.*$/zookeeper/
RULE:[2:\$1;\$2@\$0](^HTTP;.*@${realm}$)s/^.*$/HTTP/
DEFAULT
"
  if $properties and has_key($properties, 'hadoop.security.auth_to_local') {
    $auth_rules = $properties['hadoop.security.auth_to_local']
  } else {
    $auth_rules = $auth_rules_default
  }
  if $hadoop::realm and $hadoop::realm != '' {
    $sec_common_properties = {
      'hadoop.http.filter.initializers' => 'org.apache.hadoop.security.AuthenticationFilterInitializer',
      'hadoop.http.authentication.type' => 'kerberos',
      'hadoop.http.authentication.token.validity' => '36000',
      'hadoop.http.authentication.signature.secret.file' => '${user.home}/http-auth-signature-secret',
      'hadoop.http.authentication.cookie.domain' => downcase($hadoop::realm),
      'hadoop.http.authentication.simple.anonymous.allowed' => false,
      'hadoop.http.authentication.kerberos.principal' => "HTTP/_HOST@${hadoop::realm}",
      'hadoop.http.authentication.kerberos.keytab' => '${user.home}/hadoop.keytab',
      'hadoop.security.authentication' => 'kerberos',
      'hadoop.rcp.protection' => 'integrity',
      'hadoop.security.auth_to_local' => $auth_rules_default,
      'mapreduce.jobhistory.keytab' => $keytab_jobhistory,
      'mapreduce.jobhistory.principal' => "jhs/_HOST@${hadoop::realm}",
    }
    if $hdfs_enable {
      $sec_hdfs_properties = {
        'dfs.datanode.address' => '0.0.0.0:1004',
        'dfs.datanode.http.address' => '0.0.0.0:1006',
        'dfs.block.access.token.enable' => true,
        'dfs.namenode.acls.enabled' => true,
        'dfs.namenode.kerberos.principal' => $_principal_namenode,
        'dfs.namenode.kerberos.https.principal' => "host/_HOST@${hadoop::realm}",
        'dfs.namenode.keytab.file' => $keytab_namenode,
        'dfs.datanode.kerberos.principal' => "dn/_HOST@${hadoop::realm}",
        'dfs.datanode.kerberos.https.principal' => "host/_HOST@${hadoop::realm}",
        'dfs.datanode.keytab.file' => $keytab_datanode,
        'dfs.journalnode.kerberos.principal' => "jn/_HOST@${hadoop::realm}",
        'dfs.journalnode.keytab.file' => $keytab_journalnode,
        'dfs.encrypt.data.transfer' => false,
        'dfs.webhdfs.enabled' => true,
        'dfs.web.authentication.kerberos.keytab' => "${hadoop::hdfs_homedir}/hadoop.keytab",
        'dfs.web.authentication.kerberos.principal' => "HTTP/_HOST@${hadoop::realm}",
      }
    } else {
      $sec_hdfs_properties = undef
    }
    if $yarn_enable {
      $sec_yarn_properties = {
        'yarn.resourcemanager.keytab' => $keytab_resourcemanager,
        'yarn.nodemanager.keytab' => $keytab_nodemanager,
        'yarn.resourcemanager.principal' => "rm/_HOST@${hadoop::realm}",
        'yarn.nodemanager.principal' => "nm/_HOST@${hadoop::realm}",
        'yarn.nodemanager.container-executor.class' => 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor',
        'yarn.nodemanager.linux-container-executor.group' => 'hadoop',
      }
    } else {
      $sec_yarn_properties = undef
    }
    if $httpfs_hostnames and !empty($httpfs_hostnames) {
      $sec_httpfs_properties = {
        'httpfs.authentication.signature.secret.file' => "${hadoop::httpfs_homedir}/httpfs-signature.secret",
        'httpfs.authentication.type' => 'kerberos',
        # _HOST not possible here, $::fqdn required
        'httpfs.authentication.kerberos.principal' => "HTTP/${::fqdn}@${hadoop::realm}",
        'httpfs.authentication.kerberos.keytab' => $hadoop::keytab_httpfs,
        # this property is not used during login to HDFS and it is required hadoop.security.auth_to_local property in core-site.xml, but it is probably still needed for authorizations handled by HTTPFS itself
        'httpfs.authentication.kerberos.name.rules' => $auth_rules,
        'httpfs.hadoop.authentication.kerberos.keytab' => $hadoop::keytab_httpfs,
        # _HOST not possible here, $::fqdn required
        'httpfs.hadoop.authentication.kerberos.principal' => "httpfs/${::fqdn}@${hadoop::realm}",
        'httpfs.hadoop.authentication.type' => 'kerberos',
      }
    } else {
      $sec_httpfs_properties = undef
    }
    $sec_properties = merge($sec_common_properties, $sec_hdfs_properties, $sec_yarn_properties, $sec_httpfs_properties)
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

  if $hadoop::features['rmstore'] and $yarn_enable {
    if $hadoop::features['rmstore'] == 'hdfs' or ($hadoop::features['rmstore'] != 'zookeeper' and !$zookeeper_hostnames) {
      if $hadoop::hdfs_deployed {
        $rm_ss_properties = {
          'yarn.resourcemanager.recovery.enabled' => true,
          'yarn.resourcemanager.store.class' => 'org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore',
          # no hdfs://${hdfs_hostname}:${_hdfs_port_namenode} prefix - in case of HA HDFS
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
    $mh_properties_common = {
      'hadoop.security.token.service.use_ip' => false,
      'yarn.resourcemanager.bind-host' => '0.0.0.0',
    }
    if $hdfs_enable {
      $mh_properties_hdfs = {
        'dfs.namenode.https-bind-host' => '0.0.0.0',
        'dfs.namenode.http-bind-host' => '0.0.0.0',
        'dfs.namenode.rpc-bind-host' => '0.0.0.0',
        'dfs.namenode.servicerpc-bind-host' => '0.0.0.0',
      }
    } else {
      $mh_properties_hdfs = undef
    }
    $mh_properties = merge($mh_properties_common, $mh_properties_hdfs)
  } else {
    $mh_properties = undef
  }

  if $hadoop::features['aggregation'] and $yarn_enable {
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
    if $hadoop::https_keystore_keypassword {
      $keypass = $hadoop::https_keystore_keypassword
    } else {
      $keypass = $hadoop::https_keystore_password
    }
    $https_common_properties = {
      'mapreduce.jobhistory.http.policy' => 'HTTPS_ONLY',
      # it listens on 19890 automatically, but it needs to be specified anyway for tracking URL working in RM
      'mapreduce.jobhistory.webapp.address' => '0.0.0.0:19890',
      'ssl.client.truststore.location' => $hadoop::https_cacerts,
      'ssl.client.truststore.password' => $hadoop::https_cacerts_password,
      'ssl.client.truststore.type' => 'jks',
      'ssl.client.truststore.reload.interval' => '300000',
      'ssl.client.keystore.location' => '${user.home}/keystore.server',
      'ssl.client.keystore.password' => $hadoop::https_keystore_password,
      'ssl.client.keystore.keypassword' => $keypass,
      'ssl.client.keystore.type' => 'jks',
      'ssl.server.truststore.location' => $hadoop::https_cacerts,
      'ssl.server.truststore.password' => $hadoop::https_cacerts_password,
      'ssl.server.truststore.type' => 'jks',
      'ssl.server.truststore.reload.interval' => '300000',
      'ssl.server.keystore.location' => '${user.home}/keystore.server',
      'ssl.server.keystore.password' => $hadoop::https_keystore_password,
      'ssl.server.keystore.keypassword' => $keypass,
      'ssl.server.keystore.type' => 'jks',
    }
    if $hdfs_enable {
      $https_hdfs_properties = {
        'dfs.http.policy' => 'HTTPS_ONLY',
        'dfs.journalnode.kerberos.internal.spnego.principal' => "HTTP/_HOST@${hadoop::realm}",
      }
    } else {
      $https_hdfs_properties = undef
    }
    if $yarn_enable {
      $https_yarn_properties = {
        'yarn.http.policy' => 'HTTPS_ONLY',
      }
    } else {
      $https_yarn_properties = undef
    }
    $https_properties = merge($https_common_properties, $https_hdfs_properties, $https_yarn_properties)
  } else {
    $https_properties = {}
  }

  if $impala_enable and $hdfs_enable {
    $impala_properties = {
      'dfs.datanode.hdfs-blocks-metadata.enabled' => true,
      'dfs.client.file-block-storage-locations.timeout.millis' => 10000,
      'dfs.client.read.shortcircuit' => true,
      'dfs.domain.socket.path' => "${::hadoop::hdfs_socketdir}/dn.socket",
    }
  } else {
    $impala_properties = {}
  }

  if $scratch_dir and $yarn_enable {
    $scratch_properties = {
      'yarn.nodemanager.local-dirs' => "${scratch_dir}/\${user.name}/nm-local-dir",
      'yarn.nodemanager.log-dirs' => "${scratch_dir}/containers",
    }
  } else {
    $scratch_properties = {}
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
      $ha_http_properties = {
        "dfs.namenode.https-address.${hadoop::cluster_name}.nn1" => "${hdfs_hostname}:${_hdfs_port_namenode_https}",
        "dfs.namenode.https-address.${hadoop::cluster_name}.nn2" => "${hdfs_hostname2}:${_hdfs_port_namenode_https}",
      }
    } else {
      $ha_http_properties = {
        "dfs.namenode.http-address.${hadoop::cluster_name}.nn1" => "${hdfs_hostname}:${_hdfs_port_namenode_http}",
        "dfs.namenode.http-address.${hadoop::cluster_name}.nn2" => "${hdfs_hostname2}:${_hdfs_port_namenode_http}",
      }
    }
    $ha_journals = join($journalnode_hostnames, ':8485;')
    $ha_base_properties = {
      'dfs.nameservices' => $hadoop::cluster_name,
      "dfs.ha.namenodes.${hadoop::cluster_name}" => 'nn1,nn2',
      "dfs.namenode.rpc-address.${hadoop::cluster_name}.nn1" => "${hdfs_hostname}:${_hdfs_port_namenode}",
      "dfs.namenode.rpc-address.${hadoop::cluster_name}.nn2" => "${hdfs_hostname2}:${_hdfs_port_namenode}",
      'dfs.namenode.shared.edits.dir' => "qjournal://${ha_journals}:8485/${hadoop::cluster_name}",
      "dfs.client.failover.proxy.provider.${hadoop::cluster_name}" => 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider',
      'dfs.ha.fencing.methods' => 'shell(/bin/true)',
    }

    if $hadoop::ha_credentials and $hadoop::ha_digest {
      $ha_credentials_properties = {
        'ha.zookeeper.auth' => "@${hadoop::confdir}/zk-auth.txt",
        'ha.zookeeper.acl' => "@${hadoop::confdir}/zk-acl.txt",
      }
    } else {
      $ha_credentials_properties = undef
    }

    $ha_hdfs_properties = merge($ha_base_properties, $ha_http_properties, $ha_credentials_properties)
  } else {
    if $hdfs_enable {
      $ha_hdfs_properties = {
        'dfs.namenode.rpc-address' => "${hdfs_hostname}:${_hdfs_port_namenode}",
      }
    } else {
      $ha_hdfs_properties = undef
    }
  }

  # High Availability of YARN
  if $yarn_enable and $yarn_hostname and $yarn_hostname2 {
    $ha_yarn_base_properties = {
      'yarn.resourcemanager.cluster-id' => $hadoop::cluster_name,
      'yarn.resourcemanager.ha.enabled' => true,
      'yarn.resourcemanager.ha.rm-ids' => 'rm1,rm2',
      'yarn.resourcemanager.hostname.rm1' => $yarn_hostname,
      'yarn.resourcemanager.hostname.rm2' => $yarn_hostname2,
    }
    # workaround for YARN-8056 (YARN HA in Hadoop >= 3.x)
    if $https {
      $ha_yarn_http_properties = {
        'yarn.resourcemanager.webapp.https.address.rm1' => "${yarn_hostname}:8090",
        'yarn.resourcemanager.webapp.https.address.rm2' => "${yarn_hostname2}:8090",
      }
    } else {
      $ha_yarn_http_properties = {
        'yarn.resourcemanager.webapp.address.rm1' => "${yarn_hostname}:8088",
        'yarn.resourcemanager.webapp.address.rm2' => "${yarn_hostname2}:8088",
      }
    }
    $ha_yarn_properties = merge($ha_yarn_base_properties, $ha_yarn_http_properties)
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
    $zoo_yarn_base_properties = {
      'yarn.resourcemanager.ha.automatic-failover.enabled' => true,
    }
    # XXX: need limit, "host:${yarn_hostname}:rwcda" doesn't work (better proper auth anyway)
    case "${::hadoop::version}." {
      /^2(\.)?/: {
        $zoo_yarn_versioned_properties = {
          'yarn.resourcemanager.zk-acl' => 'world:anyone:rwcda',
          'yarn.resourcemanager.zk-address' => $zkquorum,
        }
      }
      default: {
        $zoo_yarn_versioned_properties = {
          'hadoop.zk.acl' => 'world:anyone:rwcda',
          'hadoop.zk.address' => $zkquorum,
        }
      }
    }
    $zoo_yarn_properties = merge($zoo_yarn_base_properties, $zoo_yarn_versioned_properties)
  } else {
    $zoo_yarn_properties = undef
  }
  $zoo_properties = merge($zoo_hdfs_properties, $zoo_yarn_properties)

  if $hadoop::nfs_hostnames and $hadoop::nfs_hostnames != undef and !empty($hadoop::nfs_hostnames) {
    $nfs_base_properties = {
      "hadoop.proxyuser.${_nfs_proxy_user}.groups" => '*',
      "hadoop.proxyuser.${_nfs_proxy_user}.hosts" => '*',
      'dfs.namenode.accesstime.precision' => '3600000',
      'nfs.dump.dir' => $hadoop::nfs_dumpdir,
      'nfs.exports.allowed.hosts' => $hadoop::nfs_exports,
    }
    if $hadoop::realm and $hadoop::realm != '' {
      $nfs_sec_properties = {
        'nfs.keytab.file' => $hadoop::keytab_nfs,
        'nfs.kerberos.principal' => "${hadoop::_nfs_proxy_user}/_HOST@${hadoop::realm}",
      }
    } else {
      $nfs_sec_properties = undef
    }
    $nfs_properties = merge($nfs_base_properties, $nfs_sec_properties)
  } else {
    $nfs_properties = undef
  }

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

  if $httpfs_hostnames and !empty($httpfs_hostnames) {
    $httpfs_properties = {
      'httpfs.hadoop.config.dir' => $hadoop::confdir,
      'hadoop.proxyuser.httpfs.hosts' => join($httpfs_hostnames, ','),
      'hadoop.proxyuser.httpfs.groups' => '*',
    }
  } else {
    $httpfs_properties = {}
  }

  if $hue_hostnames and !empty($hue_hostnames) {
      $hue_properties = {
        'httpfs.proxyuser.hue.hosts' => join($hue_hostnames, ','),
        'httpfs.proxyuser.hue.groups' => '*',
        'hadoop.proxyuser.hue.hosts' => join($hue_hostnames, ','),
        'hadoop.proxyuser.hue.groups' => '*',
      }
  } else {
    $hue_properties = {}
  }

  if $oozie_hostnames and !empty($oozie_hostnames) {
      $oozie_properties = {
        'hadoop.proxyuser.oozie.hosts' => join($oozie_hostnames, ','),
        'hadoop.proxyuser.oozie.groups' => '*',
      }
  } else {
    $oozie_properties = {}
  }

  $props = merge($::hadoop::params::properties, $hdfs_properties, $dyn_properties, $yarn_properties, $sec_properties, $auth_properties, $rm_ss_properties, $mh_properties, $agg_properties, $compress_properties, $https_properties, $impala_properties, $scratch_properties, $ha_properties, $zoo_properties, $nfs_properties, $httpfs_properties, $hue_properties, $oozie_properties, $properties)
  $descs = merge($::hadoop::params::descriptions, $descriptions)

  $_authorization = merge($preset_authorization, delete($authorization, 'rules'))

  if $hadoop::perform {
    include ::hadoop::install
    include ::hadoop::config
    include ::hadoop::service

    Class['hadoop::install']
    -> Class['hadoop::config']
    ~> Class['hadoop::service']
    -> Class['hadoop']
  }
}
