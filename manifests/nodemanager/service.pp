# == Class hadoop::nodemanager::service
# Namenode must be launched first if it is colocated with nodemanager
# (conflicting ports) (tested on hadoop 2.4.1).
#
# It works OK automatically when using from parent hadoop::service class.
#
class hadoop::nodemanager::service {
  if $hadoop::zookeeper_deployed {
    service { $hadoop::daemons['nodemanager']:
      ensure    => 'running',
      enable    => true,
      subscribe => [File['core-site.xml'], File['yarn-site.xml']],
    }

    # namenode must be launched first if it is colocated with nodemanager
    # (conflicting ports, and it's dependency anyway) (tested on hadoop 2.4.1)
    if $hadoop::daemon_namenode {
      include ::hadoop::namenode::service
      Class['hadoop::namenode::service'] -> Class['hadoop::nodemanager::service']
    }

    # resourcemanager must be launched before nodemanager
    # (on Debian YARN ResourceManager is started unconfigured and it talks nonsense to nodemanagers)
    if $hadoop::daemon_resourcemanager {
      include ::hadoop::resourcemanager::service
      Class['hadoop::resourcemanager::service'] -> Class['hadoop::nodemanager::service']
    }
  } else {
    service { $hadoop::daemons['nodemanager']:
      ensure => 'stopped',
      enable => true,
    }
  }
}
