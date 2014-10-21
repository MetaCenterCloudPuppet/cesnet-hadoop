# == Class hadoop::nodemanager::config
#
class hadoop::nodemanager::config {
	include hadoop::common::config
	include hadoop::common::hdfs::config
	include hadoop::common::mapred::config
	include hadoop::common::yarn::config

	if $hadoop::realm {
		file { "/etc/security/keytab/nm.service.keytab":
			owner => "yarn",
			group => "yarn",
			mode => "0400",
			alias => "nm.service.keytab",
			before => File["yarn-site.xml"],
		}
	}
}
