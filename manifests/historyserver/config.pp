# == Class hadoop::historyserver::config
#
class hadoop::historyserver::config {
	contain hadoop::common::config
	contain hadoop::common::hdfs::config
	contain hadoop::common::mapred::config
	contain hadoop::common::yarn::config

	if $hadoop::daemon_historyserver and $hadoop::realm {
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
