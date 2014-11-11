# == Class hadoop::resourcemanager::install
#
class hadoop::resourcemanager::install {
  include stdlib
  contain hadoop::common::install

  ensure_packages($hadoop::packages_rm)
}
