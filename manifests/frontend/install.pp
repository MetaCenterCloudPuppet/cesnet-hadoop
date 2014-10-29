class hadoop::frontend::install {
	include stdlib
	contain hadoop::common::install

	ensure_packages($hadoop::packages_client)
}
