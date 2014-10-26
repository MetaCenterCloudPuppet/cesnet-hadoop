# == Class hadoop::historyserver::install
#
class hadoop::historyserver::install {
	include stdlib
	contain hadoop::common::install

	ensure_packages($hadoop::packages_mr)
}
