# == Class: hadoop::common::install
#
# Install Hadoop packages used for all nodes.
#
class hadoop::common::install {
  include ::stdlib

  ensure_packages($hadoop::packages_common)
}
