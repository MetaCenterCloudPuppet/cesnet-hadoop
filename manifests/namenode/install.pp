class hadoop::namenode::install {
	include hadoop::common::install 
	package { $hadoop::packages_nn: }
}
