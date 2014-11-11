# == Class: hadoop::namenode::install
#
# Install Hadoop Name Node packages.
#
class hadoop::namenode::install {
	include stdlib
	contain hadoop::common::install

	ensure_packages($hadoop::packages_nn)
}
