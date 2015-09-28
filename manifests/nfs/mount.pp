# = Define: hadoop::nfs::mount
#
# Mount NFS provided by HDFS NFS gateway. If *hdfs_deployed* is false, it will unmount instead.
#
# The mountpoint doesn't have to be collocated with the HDFS NFS gateway. When collocated, *hadoop::nfs::service* is required when mounting.
#
define hadoop::nfs::mount(
  $ensure = mounted,
  $hdfs_deployed = $hadoop::hdfs_deployed,
  $nfs_hostname = $::fqdn,
  $nfs_mount_options = $hadoop::nfs_mount_options,
  $nfs_mount_base_options = 'vers=3,proto=tcp,nolock,noacl,sync',
) {
  include ::stdlib

  if !defined(Class['hadoop']) {
    fail('\'hadoop\' class is required for hadoop::nfs::mount')
  }

  $nfs_mount = $title

  if $nfs_mount_options and $nfs_mount_options != '' {
    $options = "${nfs_mount_base_options},${nfs_mount_options}"
  } else {
    $options = $nfs_mount_base_options
  }

  if $hdfs_deployed {
    $_ensure = $ensure
  } else {
    $_ensure = 'unmounted'
  }

  # no owner/permissions, it can be already mounted
  file { $nfs_mount:
    ensure => 'directory',
  }
  ->
  mount { $nfs_mount:
    ensure  => $_ensure,
    atboot  => true,
    device  => "${nfs_hostname}:/",
    fstype  => 'nfs',
    options => $options,
  }

  ensure_packages($hadoop::packages_system_nfs)
  Package[$hadoop::packages_system_nfs] -> Mount[$nfs_mount]
}
