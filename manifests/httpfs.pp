# == Class hadoop::httpfs
#
# Hadoop HTTPFS proxy.
#
class hadoop::httpfs {
  include ::hadoop::httpfs::install
  include ::hadoop::httpfs::config
  include ::hadoop::httpfs::service

  Class['hadoop::httpfs::install'] ->
  Class['hadoop::httpfs::config'] ~>
  Class['hadoop::httpfs::service'] ->
  Class['hadoop::httpfs']
}
