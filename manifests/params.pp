# == Class hadoop::params
#
# This class is meant to be called from hadoop
# It sets variables according to platform
#
class hadoop::params {
	case $::osfamily {
		'RedHat': {
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
}
