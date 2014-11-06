# == Class hadoop::params
#
# This class is meant to be called from hadoop
# It sets variables according to platform
#
class hadoop::params {
	case "$::osfamily/${::operatingsystem}" {
		'RedHat/Fedora': {
			$packages_common = [ "hadoop-common", "hadoop-common-native" ]
			$packages_nn = [ "hadoop-hdfs" ]
			$packages_rm = [ "hadoop-yarn" ]
			$packages_mr = [ "hadoop-mapreduce" ]
			$packages_nm = [ "hadoop-yarn", "hadoop-yarn-security" ]
			$packages_dn = [ "hadoop-hdfs" ]
			$packages_client = [ "hadoop-client", "hadoop-mapreduce-examples" ]
		}
		default: {
			fail("${::osfamily} (${::operatingsystem}) not supported")
		}
	}

	$hdfs_hostname = "localhost"
	$yarn_hostname = "localhost"
	$slaves = [ "localhost" ]

	$cluster_name = ""
	$replication = 1

	$hdfs_dirs = [ "file:///var/lib/hadoop-hdfs" ]
}
