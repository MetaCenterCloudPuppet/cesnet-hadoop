# == Class: hadoop
#
# Full description of class hadoop here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
class hadoop (
  $package_name = $hadoop::params::package_name,
  $service_name = $hadoop::params::service_name,
) inherits hadoop::params {

  # validate parameters here

  class { 'hadoop::install': } ->
  class { 'hadoop::config': } ~>
  class { 'hadoop::service': } ->
  Class['hadoop']
}
