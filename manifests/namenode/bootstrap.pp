# == Class hadoop::namenode::bootstrap
#
# Format Hadoop Filesystem on the second HDFS Name Node. The first Name Node needs to be already formatted, empty and running.
#
class hadoop::namenode::bootstrap {
  #
  # Not creating the directory here:
  #
  # 1) directory /var/lib/hadoop-hdfs/hdfs may be created by other
  #    daemons, format command will create the namenode subdirectory
  # 2) prefix can be different and/or there can be other replicated locations
  #
  # Also wait for the primary name node.
  #
  exec { 'hdfs-bootstrap':
    command   => 'hdfs namenode -bootstrapStandby -nonInteractive && touch /var/lib/hadoop-hdfs/.puppet-hdfs-bootstrapped',
    creates   => '/var/lib/hadoop-hdfs/.puppet-hdfs-bootstrapped',
    path      => '/bin:/usr/bin',
    user      => 'hdfs',
    require   => File[$hadoop::_hdfs_name_dirs],
    tries     => 8,
    try_sleep => 30,
  }
}
