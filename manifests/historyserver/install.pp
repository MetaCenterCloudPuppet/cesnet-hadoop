# == Class hadoop::historyserver::install
#
class hadoop::historyserver::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_mr)
  Package[$hadoop::packages_mr] -> Class['hadoop::common::postinstall']
}
