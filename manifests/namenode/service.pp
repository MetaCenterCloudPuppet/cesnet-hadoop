# == Class hadoop::namenode:service:
#
# This class is meant to be called from hadoop::namenode.
# It ensure the service is running.
#
class hadoop::namenode::service {
	contain hadoop::format

	service { "hadoop-namenode":
		ensure  => "running",
		enable => true,
		subscribe => [File["core-site.xml"], File["hdfs-site.xml"]],
		require => Class["format"],
	}
	class { "create_dirs":
		require => [Service["hadoop-namenode"], Class["format"]],
		subscribe => [Class["format"], User["mapred"]],
	}
}
