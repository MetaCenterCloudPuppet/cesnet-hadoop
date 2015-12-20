# == Class hadoop::namenode:service:
#
# This class is meant to be called from hadoop::namenode.
# It ensure the service is running.
#
class hadoop::namenode::service {
  # don't launch namenode(s) during the first "stage" (requires formatting
  # which requires journal nodes)
  if $hadoop::zookeeper_deployed {
    service { $hadoop::daemons['namenode']:
      ensure    => 'running',
      enable    => true,
      subscribe => [File['core-site.xml'], File['hdfs-site.xml']],
    }
  } else {
    service { $hadoop::daemons['namenode']:
      ensure => 'stopped',
      enable => true,
    }
  }

  # journalnode should be launched first if it is collocated with namenode
  # (to behave better during initial installation and enabled HDFS HA)
  if $hadoop::daemon_journalnode {
    include ::hadoop::journalnode::service
    Class['hadoop::journalnode::service'] -> Class['hadoop::namenode::service']
  }

  # create dirs only on the first namenode
  if $hadoop::hdfs_hostname == $::fqdn and $hadoop::zookeeper_deployed {
    contain hadoop::create_dirs

    Service[$hadoop::daemons['namenode']] -> Class['hadoop::create_dirs']
    User['mapred'] -> Class['hadoop::create_dirs']

    Service[$hadoop::daemons['namenode']] -> Hadoop::Mkdir <| |>
  }
}
