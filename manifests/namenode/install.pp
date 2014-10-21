class hadoop::namenode::install {
	contain hadoop::common::install
	package { $hadoop::packages_nn: }
}
