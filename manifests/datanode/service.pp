# == Class hadoop::datanode::service
#
class hadoop::datanode::service {
  if $hadoop::zookeeper_deployed {
    service { $hadoop::daemons['datanode']:
      ensure    => 'running',
      enable    => true,
      subscribe => [File["${hadoop::confdir}/core-site.xml"], File["${hadoop::confdir}/hdfs-site.xml"]],
    }

    if $hadoop::daemon_namenode {
      include ::hadoop::namenode::service
      Class['hadoop::namenode::service'] -> Class['hadoop::datanode::service']
    }
  } else {
    service { $hadoop::daemons['datanode']:
      ensure => 'stopped',
      enable => true,
    }
  }
}
