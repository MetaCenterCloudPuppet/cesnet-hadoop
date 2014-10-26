class hadoop::common::install {
	include stdlib

	ensure_packages($hadoop::packages_common)
}
