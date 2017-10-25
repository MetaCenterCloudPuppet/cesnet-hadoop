# == Class hadoop::frontend::config
#
# This class is called from hadoop::frontend.
#
class hadoop::frontend::config {
  contain hadoop::common::config
  if $hadoop::hdfs_hostname {
    contain hadoop::common::hdfs::config
  }
  contain hadoop::common::yarn::config
  contain hadoop::common::mapred::config
}
