# == Class hadoop::historyserver::service
#
# Namenode should be launched first if it is colocated with historyserver
# (just cosmetics, some initial exceptions in logs) (tested on hadoop 2.4.1).
#
# It works OK automatically when using from parent hadoop::service class.
#
class hadoop::historyserver::service {
  # history server requires working HDFS
  if $hadoop::hdfs_deployed {
    service { $hadoop::daemons['historyserver']:
      ensure    => 'running',
      enable    => true,
      subscribe => [File['core-site.xml'], File['yarn-site.xml']],
    }

    # namenode should be launched first if it is colocated with historyserver
    # (just cosmetics, some initial exceptions in logs) (tested on hadoop 2.4.1)
    if $hadoop::daemon_namenode {
      include ::hadoop::namenode::service
      Class['hadoop::namenode::service'] -> Class['hadoop::historyserver::service']
    }
  } else {
    service { $hadoop::daemons['historyserver']:
      ensure => 'stopped',
      enable => true,
    }
  }
}
