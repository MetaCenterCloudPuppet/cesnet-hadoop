# == Class hadoop::install
#
class hadoop::install {

  package { $hadoop::package_name:
    ensure => present,
  }
}
