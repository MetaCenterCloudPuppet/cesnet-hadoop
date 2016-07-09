# == Class: hadoop::namenode::install
#
# Install Hadoop Name Node packages.
#
class hadoop::namenode::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_nn)
  Package[$hadoop::packages_nn] -> Class['hadoop::common::postinstall']
}
