# == Class hadoop::nfs::user
#
# Create system user for NFS Gateway (if needed). The class should be included
# with NFS Gateway and also at all Namenodes.
#
class hadoop::nfs::user {
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
