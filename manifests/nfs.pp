# == Class hadoop::nfs
#
# HDFS NFS Gateway.
#
class hadoop::nfs {
  include ::hadoop::nfs::install
  include ::hadoop::nfs::config
  include ::hadoop::nfs::service

  Class['hadoop::nfs::install'] ->
  Class['hadoop::nfs::config'] ~>
  Class['hadoop::nfs::service'] ->
  Class['hadoop::nfs']
}
