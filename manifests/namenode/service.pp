# == Class hadoop::namenode:service:
#
# This class is meant to be called from hadoop::namenode.
# It ensure the service is running.
#
class hadoop::namenode::service {
  contain hadoop::create_dirs

  service { $hadoop::daemons['namenode']:
    ensure    => 'running',
    enable    => true,
    subscribe => [File['core-site.xml'], File['hdfs-site.xml']],
  }
  ->
  Class['hadoop::create_dirs']

  User['mapred'] -> Class['hadoop::create_dirs']
}
