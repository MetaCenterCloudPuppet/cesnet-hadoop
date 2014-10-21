# == Class hadoop::datanode::install
#
class hadoop::datanode::install {
	include hadoop::common::install
	package { $hadoop::packages_dn: }
}
