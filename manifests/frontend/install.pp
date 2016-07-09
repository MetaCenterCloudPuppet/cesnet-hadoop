# == Class: hadoop::frontend::install
#
# Install Hadoop client packages.
#
class hadoop::frontend::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_client)
  Package[$hadoop::packages_client] -> Class['hadoop::common::postinstall']
}
