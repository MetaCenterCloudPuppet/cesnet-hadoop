# == Class hadoop::zkfc::config
#
# This class is called from hadoop::zkfc.
#
class hadoop::zkfc::config {
  include ::stdlib
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::hdfs::daemon
}
