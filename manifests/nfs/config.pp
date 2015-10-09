# == Class hadoop::nfs::config
#
class hadoop::nfs::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::hdfs::daemon
  contain hadoop::nfs::user

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
}
