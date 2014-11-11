# == Class hadoop::nodemanager::install
#
class hadoop::nodemanager::install {
  include stdlib
  contain hadoop::common::install

  ensure_packages($hadoop::packages_nm)
}
