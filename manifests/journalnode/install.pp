# == Class hadoop::journalnode::install
#
# Install Hadoop Journal Node daemon. See also hadoop::journalnode.
#
class hadoop::journalnode::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_jn)
  Package[$hadoop::packages_jn] -> Class['hadoop::common::postinstall']
}
