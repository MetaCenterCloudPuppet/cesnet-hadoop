# == Class hadoop::datanode::config
#
class hadoop::datanode::config {
	include hadoop::common::config
	include hadoop::common::hdfs::config

	if $hadoop::realm {
		file { "/etc/security/keytab/dn.service.keytab":
			owner => "hdfs",
			group => "hdfs",
			mode => "0400",
			alias => "dn.service.keytab",
		}
	}
}
