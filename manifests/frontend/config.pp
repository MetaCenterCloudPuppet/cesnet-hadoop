# == Class hadoop::frontend::config
#
# This class is called from hadoop::namenode.
#
class hadoop::frontend::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::yarn::config
  contain hadoop::common::mapred::config
}
