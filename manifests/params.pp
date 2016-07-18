# == Class hadoop::params
#
# This class is meant to be called from hadoop
# It sets variables according to platform
#
class hadoop::params {
  $alternatives_ssl = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '',
    /Debian|RedHat/ => 'hadoop-httpfs-tomcat-conf',
  }

  case "${::osfamily}-${::operatingsystem}" {
    /RedHat-Fedora/: {
      $packages_common = [ 'hadoop-common', 'hadoop-common-native' ]
      $packages_nn = [ 'hadoop-hdfs' ]
      $packages_rm = [ 'hadoop-yarn' ]
      $packages_mr = [ 'hadoop-mapreduce' ]
      $packages_nm = [ 'hadoop-yarn', 'hadoop-yarn-security' ]
      $packages_dn = [ 'hadoop-hdfs' ]
      $packages_jn = [ 'hadoop-hdfs' ]
      $packages_hdfs_zkfc = [ 'hadoop-hdfs' ]
      $packages_client = [ 'hadoop-client', 'hadoop-mapreduce-examples' ]
      $packages_nfs = [ 'hadoop-nfs' ]
      $packages_system_nfs = [ 'nfs-utils' ]
      $packages_httpfs = [ 'hadoop-httpfs' ]

      $daemons = {
        'namenode' => 'hadoop-namenode',
        'datanode' => 'hadoop-datanode',
        'resourcemanager' => 'hadoop-resourcemanager',
        'nodemanager' => 'hadoop-nodemanager',
        'historyserver' => 'hadoop-historyserver',
        'journalnode' => 'hadoop-journalnode',
        'hdfs-zkfc' => 'hadoop-zkfc',
        'nfs' => 'hadoop-nfs',
        'portmap' => undef,
        'httpfs' => 'tomcat@httpfs',
      }
      $envs = {
        'common' => '/etc/sysconfig/hadoop',
        'datanode' => '/etc/sysconfig/hadoop-datanode',
        'nodemanager' => '/etc/sysconfig/hadoop-nodemanager',
        'historyserver' => '/etc/sysconfig/hadoop-historyserver',
        'journalnode' => '/etc/sysconfig/hadoop-journalnode',
        'hdfs-zkfc' => '/etc/sysconfig/hadoop-zkfc',
        'nfs' => '/etc/default/hadoop-nfs',
        'httpfs' => undef,
      }

      $confdir = '/etc/hadoop'
      $confdir_httpfs = undef
      # container group, official recommendation is 'hadoop'
      # depends on result of: https://bugzilla.redhat.com/show_bug.cgi?id=1163892
      $yarn_group = 'hadoop'
    }
    /Debian|RedHat/: {
      $packages_common = [ ]
      $packages_nn = [ 'hadoop-hdfs-namenode' ]
      $packages_rm = [ 'hadoop-yarn-resourcemanager' ]
      $packages_mr = [ 'hadoop-mapreduce-historyserver' ]
      $packages_nm = [ 'hadoop-yarn-nodemanager' ]
      $packages_dn = [ 'hadoop-hdfs-datanode' ]
      $packages_jn = [ 'hadoop-hdfs-journalnode' ]
      $packages_hdfs_zkfc = [ 'hadoop-hdfs-zkfc' ]
      $packages_client = [ 'hadoop-client', 'hadoop-doc' ]
      $packages_nfs = $::osfamily ? {
        /Debian/ => [ 'hadoop-hdfs-nfs3' ],
        /RedHat/ => [ 'hadoop-hdfs-nfs3' ],
      }
      $packages_system_nfs = $::osfamily ? {
        /Debian/ => [ 'nfs-common' ],
        /RedHat/ => [ 'nfs-utils' ],
      }
      $packages_httpfs = ['hadoop-httpfs']

      $daemons = {
        'namenode' => 'hadoop-hdfs-namenode',
        'datanode' => 'hadoop-hdfs-datanode',
        'resourcemanager' => 'hadoop-yarn-resourcemanager',
        'nodemanager' => 'hadoop-yarn-nodemanager',
        'historyserver' => 'hadoop-mapreduce-historyserver',
        'journalnode' => 'hadoop-hdfs-journalnode',
        'hdfs-zkfc' => 'hadoop-hdfs-zkfc',
        'nfs' => 'hadoop-hdfs-nfs3',
        'portmap' => $::osfamily ? {
          /Debian/ => undef,
          /RedHat/ => 'rpcbind',
        },
        'httpfs' => 'hadoop-httpfs',
      }
      $envs = {
        'common' => '/etc/default/hadoop',
        'datanode' => '/etc/default/hadoop-hdfs-datanode',
        'nodemanager' => '/etc/default/hadoop-yarn-nodemanager',
        'historyserver' => '/etc/default/hadoop-mapreduce-historyserver',
        'journalnode' => '/etc/default/hadoop-hdfs-journalnode',
        'hdfs-zkfc' => '/etc/default/hadoop-hdfs-zkfc',
        'nfs' => '/etc/default/hadoop-hdfs-nfs3',
        'httpfs' => '/etc/default/hadoop-httpfs',
      }

      $confdir = '/etc/hadoop/conf'
      $confdir_httpfs = '/etc/hadoop-httpfs/conf'
      # container group
      $yarn_group = 'yarn'
    }
    default: {
      fail("${::osfamily} (${::operatingsystem}) not supported")
    }
  }

  $cluster_name = 'cluster'

  $descriptions = {
    'dfs.client.file-block-storage-locations.timeout.millis' => 'optimization for Impala',
    'dfs.client.read.shortcircuit' => 'optimization for Impala',
    'dfs.domain.socket.path' => 'optimization for Impala',
    'dfs.datanode.hdfs-blocks-metadata.enabled' => 'required for Impala',
    'dfs.hosts' => 'permitted data nodes',
    'dfs.hosts.exclude' => 'decommissioning of data nodes',
    'dfs.namenode.accesstime.precision' => 'the access time for an HDFS file is precise up to this value, setting a value of 0 disables access times for HDFS',
    'dfs.namenode.http-bind-host' => 'bind address for HDFS HTTP (must be used 0.0.0.0 hack for multihome)',
    'dfs.namenode.https-bind-host' => 'bind address for HDFS HTTP (must be used 0.0.0.0 hack for multihome)',
    'dfs.namenode.rpc-bind-host' => 'bind address for HDFS RPC (must be used 0.0.0.0 hack for multihome)',
    'dfs.namenode.servicerpc-bind-host' => 'bind address for HDFS service RPC (must be used 0.0.0.0 hack for multihome)',
    'hadoop.rcp.protection' => 'authentication, integrity, privacy',
    'hadoop.security.auth_to_local' => 'give Kerberos principles proper groups (through mapping to local users), also useful when default realm is different from the service principals',
    'hadoop.security.authorization' => 'enable authorization, see hadoop-policy.xml',
    'hadoop.security.token.service.use_ip' => 'use IP instead of hostnames in Hadoop tokens (must me switched off for multihome)',
    'dfs.datanode.address' => 'different port with security enabled (original port 50010)',
    'dfs.datanode.http.address' => 'different port with security enabled (original port 50075)',
    'dfs.webhdfs.enabled' => 'read-only Web HDFS access',
    'mapreduce.jobhistory.address' => 'bind address for MapRed Job History Server, but it is also required to be real hostname for Oozie',
    'mapreduce.map.output.compress' => 'compression of intermediate files',
    'mapreduce.map.output.compress.codec' => 'compression codec of intermediate files',
    'mapreduce.task.tmp.dir' => 'temporary directory for map and reduce tasks',
    'mapreduce.tasktracker.outofband.heartbeat' => 'let the TaskTracker send an out-of-band heartbeat on task completion to reduce latency',
    'yarn.nodemanager.local-dirs' => 'List of directories to store localized files in.',
    'yarn.nodemanager.log-dirs' => 'Where to store container logs',
    'yarn.resourcemanager.bind-host' => 'bind address for RM (must be used 0.0.0.0 hack for multihome)',
    'yarn.resourcemanager.recovery.enabled' => 'enable resubmit old jobs on start',
    'yarn.resourcemanager.zk-acl' => 'default is world:anyone:rwcda',
    'yarn.application.classpath' => 'Classpath for typical applications.',
    'yarn.resourcemanager.nodes.include-path' => 'permitted nodes',
    'yarn.resourcemanager.nodes.exclude-path' => 'decommissioning of the nodes',
  }
  $features = {
  }
  $https = undef
  $https_cacerts = '/etc/security/cacerts'
  $https_cacerts_password = ''
  $https_keystore = '/etc/security/server.keystore'
  $https_keystore_password = 'changeit'
  $https_keystore_keypassword = undef

  $hdfs_dir = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/var/lib/hadoop-hdfs',
    /Debian|RedHat/ => '/var/lib/hadoop-hdfs/cache',
  }
  $hdfs_name_dirs = [ $hdfs_dir ]
  $hdfs_data_dirs = [ $hdfs_dir ]
  # just cosmetics, daemons will create these directories automatically anyway
  $hdfs_namenode_suffix = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/${user.name}/dfs/namenode',
    /Debian|RedHat/ => '/${user.name}/dfs/name',
  }
  $hdfs_secondarynamenode_suffix = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/${user.name}/dfs/secondarynamenode',
    /Debian|RedHat/ => '/${user.name}/dfs/secondaryname',
  }
  $hdfs_datanode_suffix = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/${user.name}/dfs/datanode',
    /Debian|RedHat/ => '/${user.name}/dfs/data',
  }
  $hdfs_journalnode_suffix = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/${user.name}/dfs/journalnode',
    /Debian|RedHat/ => '/${user.name}/dfs/journal',
  }
  $hdfs_homedir = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/var/lib/hadoop-hdfs',
    /Debian|RedHat/ => '/var/lib/hadoop-hdfs',
  }
  $httpfs_homedir = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => undef,
    /Debian|RedHat/ => '/var/lib/hadoop-httpfs',
  }
  $yarn_homedir = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/var/cache/hadoop-yarn',
    /Debian|RedHat/ => '/var/lib/hadoop-yarn',
  }
  $mapred_homedir = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/var/cache/hadoop-mapreduce',
    /Debian|RedHat/ => '/var/lib/hadoop-mapreduce',
  }
  $hdfs_socketdir = '/var/run/hadoop-hdfs'
  $nfs_dumpdir = '/tmp/.hdfs-nfs'
  $nfs_mount = '/hdfs'
  $nfs_system_user = 'hdfs'
  $nfs_system_group = 'hdfs'
  $default_uid_min = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => 1000,
    /RedHat/        => 500,
    default         => 1000,
  }
  if getvar('::uid_min') {
    $uid_min = $::uid_min
  } else {
    $uid_min = $default_uid_min
  }

  # other properties added to init.pp
  case "${::osfamily}-${::operatingsystem}" {
    /RedHat-Fedora/: {
      $properties = {
        'yarn.nodemanager.local-dirs' => "${yarn_homedir}/\${user.name}/nm-local-dir",
        'yarn.application.classpath' => '
        $HADOOP_CONF_DIR,$HADOOP_COMMON_HOME/$HADOOP_COMMON_DIR/*,
        $HADOOP_COMMON_HOME/$HADOOP_COMMON_LIB_JARS_DIR/*,
        $HADOOP_HDFS_HOME/$HDFS_DIR/*,$HADOOP_HDFS_HOME/$HDFS_LIB_JARS_DIR/*,
        $HADOOP_MAPRED_HOME/$MAPRED_DIR/*,
        $HADOOP_MAPRED_HOME/$MAPRED_LIB_JARS_DIR/*,
        $HADOOP_YARN_HOME/$YARN_DIR/*,$HADOOP_YARN_HOME/$YARN_LIB_JARS_DIR/*
',
      }
    }
    /Debian|RedHat/: {
      $properties = {
        'yarn.nodemanager.local-dirs' => "${yarn_homedir}/cache/\${user.name}/nm-local-dir",
        'yarn.application.classpath' => '
        $HADOOP_CONF_DIR,
        $HADOOP_COMMON_HOME/*,$HADOOP_COMMON_HOME/lib/*,
        $HADOOP_HDFS_HOME/*,$HADOOP_HDFS_HOME/lib/*,
        $HADOOP_MAPRED_HOME/*,$HADOOP_MAPRED_HOME/lib/*,
        $HADOOP_YARN_HOME/*,$HADOOP_YARN_HOME/lib/*
',
      }
    }
    default: {
      fail("${::osfamily} (${::operatingsystem}) not supported")
    }
  }

  $perform = false
  $hdfs_deployed = true
  $zookeeper_deployed = true

  $https_keytab = '/etc/security/keytab/http.service.keytab'
  $keytab_namenode = '/etc/security/keytab/nn.service.keytab'
  $keytab_datanode = '/etc/security/keytab/dn.service.keytab'
  $keytab_httpfs = '/etc/security/keytab/httpfs-http.service.keytab'
  $keytab_jobhistory = '/etc/security/keytab/jhs.service.keytab'
  $keytab_journalnode = '/etc/security/keytab/jn.service.keytab'
  $keytab_resourcemanager = '/etc/security/keytab/rm.service.keytab'
  $keytab_nodemanager = '/etc/security/keytab/nm.service.keytab'
  $keytab_nfs = '/etc/security/keytab/nfs.service.keytab'
}
