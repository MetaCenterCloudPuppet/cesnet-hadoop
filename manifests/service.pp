# == Class hadoop::service
#
# This class is meant to be called from hadoop
# It ensure the service is running
#
class hadoop::service {

  service { $hadoop::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
