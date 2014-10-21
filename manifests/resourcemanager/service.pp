# == Class hadoop::resourcemanager::service
#
# This class is meant to be called from hadoop.
# It ensure the services are running.
#
class hadoop::resourcemanager::service {
	contain hadoop::common::config
	contain hadoop::common::yarn::config

	service { "hadoop-resourcemanager":
		ensure  => "running",
		enable => true,
		subscribe => [File["core-site.xml"], File["yarn-site.xml"]],
	}
}
