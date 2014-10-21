# == Class hadoop::resourcemanager::install
#
class hadoop::resourcemanager::install {
	contain hadoop::common::install
	package { $hadoop::packages_rm: }
}
