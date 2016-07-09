# == Class hadoop::nfs::install
#
class hadoop::nfs::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_system_nfs)
  ensure_packages($hadoop::packages_nfs)
  Package[$hadoop::packages_nfs] -> Class['hadoop::common::postinstall']
}
