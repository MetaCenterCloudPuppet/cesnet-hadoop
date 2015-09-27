# == Class hadoop::nfs::config
#
class hadoop::nfs::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::hdfs::daemon

  #$env_nfs = $hadoop::envs['nfs']
  #augeas{$env_nfs:
  #  lens    => 'Shellvars.lns',
  #  incl    => $env_nfs,
  #  changes => template('hadoop/env/hdfs-nfs.augeas.erb'),
  #}
  #notice(template('hadoop/env/hdfs-nfs.augeas.erb'))

  if $hadoop::realm and $hadoop::realm != '' {
    file { $hadoop::keytab_nfs:
      owner  => $hadoop::nfs_system_user,
      group  => $hadoop::nfs_system_group,
      mode   => '0400',
      alias  => 'nfs.service.keytab',
      before => File['hdfs-site.xml'],
    }

  }

  # proxy user needed only if it doesn't exist in the system
  if $hadoop::_nfs_proxy_user != 'hdfs' and $hadoop::_nfs_proxy_user != $hadoop::nfs_system_user {
    group { $hadoop::_nfs_proxy_user:
      ensure => present,
      system => true,
    }
    ->
    user { $hadoop::_nfs_proxy_user:
      ensure     => present,
      gid        => $hadoop::_nfs_proxy_user,
      home       => '/var/lib/hadoop-nfs',
      managehome => true,
      password   => '!!',
      shell      => '/bin/false',
      system     => true,
    }
  }
}
