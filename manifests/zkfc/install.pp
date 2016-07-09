# == Class: hadoop::zkfc::install
#
# Install Hadoop Name Node Zookeeper client packages.
#
class hadoop::zkfc::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_hdfs_zkfc)
  Package[$hadoop::packages_hdfs_zkfc] -> Class['hadoop::common::postinstall']
}
