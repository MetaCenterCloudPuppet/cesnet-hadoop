# == Class hadoop::params
#
# This class is meant to be called from hadoop
# It sets variables according to platform
#
class hadoop::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'hadoop'
      $service_name = 'hadoop'
    }
    'RedHat', 'Amazon': {
      $package_name = 'hadoop'
      $service_name = 'hadoop'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
