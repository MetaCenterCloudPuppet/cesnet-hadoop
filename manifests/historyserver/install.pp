# == Class hadoop::historyserver::install
#
class hadoop::historyserver::install {
	contain hadoop::common::install
	package { $hadoop::packages_mr: }
}
