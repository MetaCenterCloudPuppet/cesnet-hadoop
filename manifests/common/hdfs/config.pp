# == Class hadoop::common::hdfs::config
#
class hadoop::common::hdfs::config {
  include hadoop::common::install
  include hadoop::common::slaves

  file { "${hadoop::confdir}/hdfs-site.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'hdfs-site.xml',
    content => template('hadoop/hadoop/hdfs-site.xml.erb'),
    require => [ Exec['touch-excludes'], File['slaves'] ],
  }

  # mapred user is required on name node,
  # it is created by hadoop-yarn package too, but we don't need yarn package with
  # all dependencies just for creating this user
  group { 'mapred':
    ensure => present,
    system => true,
  }
  case "${::osfamily}/${::operatingsystem}" {
    'RedHat/Fedora': {
      user { 'mapred':
        ensure     => present,
        comment    => 'Apache Hadoop MapReduce',
        password   => '!!',
        shell      => '/sbin/nologin',
        home       => '/var/cache/hadoop-mapreduce',
        managehome => true,
        system     => true,
        gid        => 'mapred',
        groups     => [ 'hadoop' ],
        require    => [Group['mapred']]
      }
    }
    'Debian/Debian': {
      user { 'mapred':
        ensure     => present,
        comment    => 'Hadoop MapReduce',
        password   => '!!',
        shell      => '/bin/bash',
        home       => '/var/lib/hadoop-mapreduce',
        managehome => true,
        system     => true,
        gid        => 'mapred',
        groups     => [ 'hadoop' ],
        require    => [Group['mapred']]
      }
    }
    default: {
      fail("${::osfamily} (${::operatingsystem}) not supported")
    }
  }

  #
  # rm user (from principle) is required for ResourceManager state-store
  # working with Kerberos
  #
  # org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore
  # ignores hadoop.security.auth_to_local
  #
  $rm_shell = $::osfamily ? {
    'RedHat' => '/sbin/nologin',
    'Debian' => '/bin/false',
  }
  if ($hadoop::realm) {
    user { 'rm':
      ensure     => present,
      comment    => 'Apache Hadoop Yarn',
      password   => '!!',
      shell      => $rm_shell,
      home       => '/var/cache/hadoop-yarn',
      managehome => false,
      system     => true,
      gid        => 'mapred',
      groups     => [ 'hadoop' ],
      require    => [Group['mapred']]
    }
  }

  # slaves needs Hadoop configuration directory
  Class['hadoop::common::install'] -> Class['hadoop::common::slaves']
}
