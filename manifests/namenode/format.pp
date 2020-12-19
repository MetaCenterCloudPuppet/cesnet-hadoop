# == Class hadoop::namenode::format
#
# Format Hadoop Filesystem. When you need to re-format again, you must remove the datanode directory (and also clean all datanodes in cluster!).
#
class hadoop::namenode::format {
  if $hadoop::cluster_name and $hadoop::cluster_name != '' {
    $format_args = "-clusterid ${hadoop::cluster_name}"
  } else {
    $format_args = ''
  }
  # 1) directory /var/lib/hadoop-hdfs/hdfs may be created by other
  #    daemons, format command will create the namenode subdirectory
  # 2) prefix can be different and/or there can be other replicated locations
  exec { 'hdfs-format':
    command => "hdfs namenode -format -nonInteractive ${format_args} >> /var/lib/hadoop-hdfs/puppet-hdfs-format.log 2>&1 && touch /var/lib/hadoop-hdfs/.puppet-hdfs-formatted",
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-formatted',
    path    => '/bin:/usr/bin',
    user    => 'hdfs',
    require => File[$hadoop::_hdfs_name_dirs],
  }

  # only when converting existing non-HA HDFS cluster
  ## if there are any journal nodes, initialize them too
  #if $hadoop::journalnode_hostnames {
  #  exec { 'hdfs-journal-init':
  #    command => "hdfs namenode -initializeSharedEdits && touch /var/lib/hadoop-hdfs/.puppet-journal-initialized",
  #    creates => '/var/lib/hadoop-hdfs/.puppet-journal-initialized',
  #    path    => '/bin:/usr/bin',
  #    user    => 'hdfs',
  #    require => File [ $hadoop::_hdfs_journal_dirs ],
  #  }
  #}
}
