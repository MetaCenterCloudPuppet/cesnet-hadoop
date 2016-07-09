# == Class hadoop::common::hdfs::config
#
class hadoop::common::hdfs::config {
  include ::hadoop::common::install
  include ::hadoop::common::slaves

  if $hadoop::datanode_hostnames {
    $file_slaves = 'slaves-hdfs'

    file { "${hadoop::confdir}/slaves-hdfs":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      alias   => 'slaves-hdfs',
      content => template('hadoop/hadoop/slaves-hdfs.erb'),
    }
  } else {
    $file_slaves = 'slaves'

    file { "${hadoop::confdir}/slaves-hdfs":
      ensure  => absent,
    }
  }
  file { "${hadoop::confdir}/hdfs-site.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'hdfs-site.xml',
    content => template('hadoop/hadoop/hdfs-site.xml.erb'),
    require => [ Exec['touch-excludes'], File[$file_slaves] ],
  }

  if $hadoop::ha_credentials {
    file { "${hadoop::confdir}/zk-auth.txt":
      owner   => 'hdfs',
      group   => 'hdfs',
      mode    => '0600',
      alias   => 'zk-auth.txt',
      content => template('hadoop/hadoop/zk-auth.txt.erb'),
    }
  } else {
    file { "${hadoop::confdir}/zk-auth.txt":
      ensure => absent,
    }
  }

  if $hadoop::ha_digest {
    file { "${hadoop::confdir}/zk-acl.txt":
      owner   => 'hdfs',
      group   => 'hdfs',
      mode    => '0600',
      alias   => 'zk-acl.txt',
      content => template('hadoop/hadoop/zk-acl.txt.erb'),
    }
  } else {
    file { "${hadoop::confdir}/zk-acl.txt":
      ensure => absent,
    }
  }

  # mapred user is required on name node,
  # it is created by hadoop-yarn package too, but we don't need yarn package with
  # all dependencies just for creating this user
  group { 'mapred':
    ensure => present,
    system => true,
  }
  case "${::osfamily}-${::operatingsystem}" {
    /RedHat-Fedora/: {
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
        require    => [Group['mapred']],
      }
    }
    /Debian|RedHat/: {
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
        require    => [Group['mapred']],
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
  $rm_shell = "${::osfamily}-${::operatingsystem}" ? {
    /RedHat-Fedora/ => '/sbin/nologin',
    /Debian|RedHat/ => '/bin/false',
  }
  if $hadoop::realm and $hadoop::realm != '' {
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
      require    => [Group['mapred']],
    }
  }

  # slaves needs Hadoop configuration directory
  Class['hadoop::common::install'] -> Class['hadoop::common::slaves']

  #
  # Nfs proxy user is required on name node.
  #
  # It is created by hadoop::nfs class, but NFS Gateway may not be installed
  # at the name node.
  #
  if $hadoop::nfs_properties {
    contain hadoop::nfs::user
  }
}
