# == Class hadoop::params
#
# This class is meant to be called from hadoop
# It sets variables according to platform
#
class hadoop::params {
  case "${::osfamily}/${::operatingsystem}" {
    'RedHat/Fedora': {
      $packages_common = [ 'hadoop-common', 'hadoop-common-native' ]
      $packages_nn = [ 'hadoop-hdfs' ]
      $packages_rm = [ 'hadoop-yarn' ]
      $packages_mr = [ 'hadoop-mapreduce' ]
      $packages_nm = [ 'hadoop-yarn', 'hadoop-yarn-security' ]
      $packages_dn = [ 'hadoop-hdfs' ]
      $packages_jn = [ 'hadoop-hdfs' ]
      $packages_hdfs_zkfc = [ 'hadoop-hdfs' ]
      $packages_client = [ 'hadoop-client', 'hadoop-mapreduce-examples' ]

      $daemons = {
        'namenode' => 'hadoop-namenode',
        'datanode' => 'hadoop-datanode',
        'resourcemanager' => 'hadoop-resourcemanager',
        'nodemanager' => 'hadoop-nodemanager',
        'historyserver' => 'hadoop-historyserver',
        'journalnode' => 'hadoop-journalnode',
        'hdfs-zkfc' => 'hadoop-zkfc',
      }
      $envs = {
        'common' => '/etc/sysconfig/hadoop',
        'datanode' => '/etc/sysconfig/hadoop-datanode',
        'nodemanager' => '/etc/sysconfig/hadoop-nodemanager',
        'historyserver' => '/etc/sysconfig/hadoop-historyserver',
        'journalnode' => '/etc/sysconfig/hadoop-journalnode',
        'hdfs-zkfc' => '/etc/sysconfig/hadoop-zkfc',
      }

      $alternatives = undef
      $confdir = '/etc/hadoop'
      # container group, official recommendation is 'hadoop'
      # depends on result of: https://bugzilla.redhat.com/show_bug.cgi?id=1163892
      $yarn_group = 'hadoop'

      # other properties added in init.pp
      $properties = {
        'yarn.nodemanager.local-dirs' => '/var/cache/hadoop-yarn/${user.name}/nm-local-dir',
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
    'Debian/Debian': {
      $packages_common = [ ]
      $packages_nn = [ 'hadoop-hdfs-namenode' ]
      $packages_rm = [ 'hadoop-yarn-resourcemanager' ]
      $packages_mr = [ 'hadoop-mapreduce-historyserver' ]
      $packages_nm = [ 'hadoop-yarn-nodemanager' ]
      $packages_dn = [ 'hadoop-hdfs-datanode' ]
      $packages_jn = [ 'hadoop-hdfs-journalnode' ]
      $packages_hdfs_zkfc = [ 'hadoop-hdfs-zkfc' ]
      $packages_client = [ 'hadoop-client', 'hadoop-doc' ]

      $daemons = {
        'namenode' => 'hadoop-hdfs-namenode',
        'datanode' => 'hadoop-hdfs-datanode',
        'resourcemanager' => 'hadoop-yarn-resourcemanager',
        'nodemanager' => 'hadoop-yarn-nodemanager',
        'historyserver' => 'hadoop-mapreduce-historyserver',
        'journalnode' => 'hadoop-hdfs-journalnode',
        'hdfs-zkfc' => 'hadoop-hdfs-zkfc',
      }
      $envs = {
        'common' => '/etc/default/hadoop',
        'datanode' => '/etc/default/hadoop-hdfs-datanode',
        'nodemanager' => '/etc/default/hadoop-yarn-nodemanager',
        'historyserver' => '/etc/default/hadoop-mapreduce-historyserver',
        'journalnode' => '/etc/default/hadoop-hdfs-journalnode',
        'hdfs-zkfc' => '/etc/default/hadoop-hdfs-zkfc',
      }

      $alternatives = 'cluster'
      $confdir = '/etc/hadoop/conf'
      # container group
      $yarn_group = 'yarn'

      # other properties added in init.pp
      $properties = {
        'yarn.nodemanager.local-dirs' => '/var/lib/hadoop-yarn/cache/${user.name}/nm-local-dir',
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

  $hdfs_hostname = 'localhost'
  $yarn_hostname = 'localhost'
  $slaves = [ 'localhost' ]

  $cluster_name = 'cluster'

  $descriptions = {
    'dfs.hosts' => 'permitted data nodes',
    'dfs.hosts.exclude' => 'decommissioning of data nodes',
    'dfs.namenode.rpc-bind-host' => 'bind address for HDFS RPC (must be used 0.0.0.0 hack for multihome)',
    'hadoop.rcp.protection' => 'authentication, integrity, privacy',
    'hadoop.security.auth_to_local' => 'give Kerberos principles proper groups (through mapping to local users), also useful when default realm is different from the service principals',
    'hadoop.security.authorization' => 'enable authorization, see hadoop-policy.xml',
    'hadoop.security.token.service.use_ip' => 'use IP instead of hostnames in Hadoop tokens (must me switched off for multihome)',
    'dfs.datanode.address' => 'different port with security enabled (original port 50010)',
    'dfs.datanode.http.address' => 'different port with security enabled (original port 50075)',
    'dfs.webhdfs.enabled' => 'read-only Web HDFS access',
    'mapreduce.task.tmp.dir' => 'temporary directory for map and reduce tasks',
    'mapreduce.tasktracker.outofband.heartbeat' => 'let the TaskTracker send an out-of-band heartbeat on task completion to reduce latency',
    'yarn.nodemanager.local-dirs' => 'List of directories to store localized files in.',
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

  $hdfs_dir = $::osfamily ? {
    'Debian' => '/var/lib/hadoop-hdfs/cache',
    'RedHat' => '/var/lib/hadoop-hdfs',
  }
  $hdfs_name_dirs = [ $hdfs_dir ]
  $hdfs_data_dirs = [ $hdfs_dir ]
  # just cosmetics, daemons will create these directories automatically anyway
  $hdfs_namenode_suffix = $::osfamily ? {
    'RedHat' => '/${user.name}/dfs/namenode',
    'Debian' => '/${user.name}/dfs/name',
  }
  $hdfs_secondarynamenode_suffix = $::osfamily ? {
    'RedHat' => '/${user.name}/dfs/secondarynamenode',
    'Debian' => '/${user.name}/dfs/secondaryname',
  }
  $hdfs_datanode_suffix = $::osfamily ? {
    'RedHat' => '/${user.name}/dfs/datanode',
    'Debian' => '/${user.name}/dfs/data',
  }
  $hdfs_journalnode_suffix = $::osfamily ? {
    'RedHat' => '/${user.name}/dfs/journalnode',
    'Debian' => '/${user.name}/dfs/journal',
  }
  $hdfs_homedir = $::osfamily ? {
    'Debian' => '/var/lib/hadoop-hdfs',
    'RedHat' => '/var/lib/hadoop-hdfs',
  }
  $yarn_homedir = $::osfamily ? {
    'Debian' => '/var/lib/hadoop-yarn',
    'RedHat' => '/var/cache/hadoop-yarn',
  }
  $mapred_homedir = $::osfamily ? {
    'Debian' => '/var/lib/hadoop-mapreduce',
    'RedHat' => '/var/cache/hadoop-mapreduce',
  }
  $perform = false
  $hdfs_deployed = true

  $https_keytab = '/etc/security/keytab/http.service.keytab'
  $keytab_namenode = '/etc/security/keytab/nn.service.keytab'
  $keytab_datanode = '/etc/security/keytab/dn.service.keytab'
  $keytab_jobhistory = '/etc/security/keytab/jhs.service.keytab'
  $keytab_journalnode = '/etc/security/keytab/jn.service.keytab'
  $keytab_resourcemanager = '/etc/security/keytab/rm.service.keytab'
  $keytab_nodemanager = '/etc/security/keytab/nm.service.keytab'
}
