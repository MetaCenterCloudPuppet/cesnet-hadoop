# == Class hadoop::datanode::install
#
class hadoop::datanode::install {
  include stdlib
  contain hadoop::common::install

  ensure_packages($hadoop::packages_dn)
}
