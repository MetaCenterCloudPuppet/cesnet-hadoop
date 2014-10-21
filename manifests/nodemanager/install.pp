# == Class hadoop::nodemanager::install
#
class hadoop::nodemanager::install {
	include hadoop::common::install
	package { $hadoop::packages_nm: }
}
