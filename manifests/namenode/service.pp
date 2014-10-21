# == Class hadoop::namenode:service:
#
# This class is meant to be called from hadoop::namenode.
# It ensure the service is running.
#
class hadoop::namenode::service {
	class { "format":
		before => Service["hadoop-namenode"],
	}
	service { "hadoop-namenode":
		ensure  => "running",
		enable => true,
		subscribe => [File["core-site.xml"], File["hdfs-site.xml"]],
	}
	class { "create_dirs":
		require => [Service["hadoop-namenode"], Class["format"]],
		subscribe => [Class["format"], User["mapred"]],
	}
}
