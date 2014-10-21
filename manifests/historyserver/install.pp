# == Class hadoop::historyserver::install
#
class hadoop::historyserver::install {
	include hadoop::common::install
	package { $hadoop::packages_mr: }
}
