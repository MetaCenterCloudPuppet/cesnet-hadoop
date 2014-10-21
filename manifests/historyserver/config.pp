# == Class hadoop::historyserver::config
#
class hadoop::historyserver::config {
	include hadoop::common::config
	include hadoop::common::hdfs::config
	include hadoop::common::mapred::config
	include hadoop::common::yarn::config

	if $hadoop::realm {
		if $hadoop::daemon_historyserver {
			file { "/etc/security/keytab/jhs.service.keytab":
				owner => "mapred",
				group => "mapred",
				mode => "0400",
				alias => "jhs.service.keytab",
				before => File["mapred-site.xml"],
			}
		}
	}
}
