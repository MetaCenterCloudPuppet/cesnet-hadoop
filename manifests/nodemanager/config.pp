# == Class hadoop::nodemanager::config
#
class hadoop::nodemanager::config {
	contain hadoop::common::config
	contain hadoop::common::hdfs::config
	contain hadoop::common::mapred::config
	contain hadoop::common::yarn::config

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
