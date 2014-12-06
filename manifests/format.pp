# == Class hadoop::format
#
# Format Hadoop Filesystem. When you need to re-format again, you must remove the datanode directory (and also clean all datanodes in cluster!).
#
# This class is called from hadoop.
#
class hadoop::format {
  # if any directory layout has been created, it should be created again
  exec { 'hdfs-format-cleanup':
    command => 'rm -f /var/lib/hadoop-hdfs/.puppet-hdfs-root-created',
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-formatted',
    path    => '/bin:/usr/bin',
    user    => 'hdfs',
  }
  ->
  # 1) directory /var/lib/hadoop-hdfs/hdfs may be created by other
  #    daemons, format command will create the namenode subdirectory
  # 2) prefix can be different and/or there can be other replicated locations
  exec { 'hdfs-format':
    command => "hdfs namenode -format ${hadoop::cluster_name} && touch /var/lib/hadoop-hdfs/.puppet-hdfs-formatted",
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-formatted',
    path    => '/bin:/usr/bin',
    user    => 'hdfs',
    require => File [ $hadoop::hdfs_dirs ],
  }
}
