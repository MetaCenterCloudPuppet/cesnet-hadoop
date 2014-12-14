# == Class hadoop::namenode:service:
#
# This class is meant to be called from hadoop::namenode.
# It ensure the service is running.
#
class hadoop::namenode::service {
  service { $hadoop::daemons['namenode']:
    ensure    => 'running',
    enable    => true,
    subscribe => [File['core-site.xml'], File['hdfs-site.xml']],
  }

  # create dirs only on the first namenode
  if $hadoop::hdfs_hostname == $::fqdn and $hadoop::hdfs_deployed {
    contain hadoop::create_dirs

    Service[$hadoop::daemons['namenode']] -> Class['hadoop::create_dirs']
    User['mapred'] -> Class['hadoop::create_dirs']
  }
}
