# == Class hadoop::resourcemanager::install
#
class hadoop::resourcemanager::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_rm)
  Package[$hadoop::packages_rm] -> Class['hadoop::common::postinstall']
}
