# == Class hadoop::nodemanager::install
#
class hadoop::nodemanager::install {
	contain hadoop::common::install
	package { $hadoop::packages_nm: }
}
