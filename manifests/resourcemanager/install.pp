# == Class hadoop::resourcemanager::install
#
class hadoop::resourcemanager::install {
	include hadoop::common::install
	package { $hadoop::packages_rm: }
}
