# == Class hadoop::nodemanager::install
#
class hadoop::nodemanager::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_nm)
  Package[$hadoop::packages_nm] -> Class['hadoop::common::postinstall']
}
