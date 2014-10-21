# == Class hadoop::datanode::install
#
class hadoop::datanode::install {
	contain hadoop::common::install
	package { $hadoop::packages_dn: }
}
