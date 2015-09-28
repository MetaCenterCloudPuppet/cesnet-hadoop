# == Class hadoop::frontend
#
# Hadoop client and examples.
#
class hadoop::frontend {
  include ::hadoop::frontend::install
  include ::hadoop::frontend::config
  include ::hadoop::frontend::service

  Class['hadoop::frontend::install'] ->
  Class['hadoop::frontend::config'] ~>
  Class['hadoop::frontend::service'] ->
  Class['hadoop::frontend']
}
