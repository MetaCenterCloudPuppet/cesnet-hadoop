# == Class hadoop::datanode::install
#
class hadoop::datanode::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_dn)
  Package[$hadoop::packages_dn] -> Class['hadoop::common::postinstall']
}
