# == Class hadoop::resourcemanager::config
#
class hadoop::resourcemanager::config {
	contain hadoop::common::config
	contain hadoop::common::mapred::config
	contain hadoop::common::yarn::config

	if $hadoop::daemon_resourcemanager {
		if ($hadoop::realm) {
			file { "/etc/security/keytab/rm.service.keytab":
				owner => "yarn",
				group => "yarn",
				mode => "0400",
				alias => "rm.service.keytab",
			}
		}

		if $hadoop::features["rmrestart"] {
			file { "/etc/cron.d/hadoop-resourcemanager-restarts":
				owner => "root",
				group => "root",
				mode => "0644",
				alias => "rm-cron",
				content => template("hadoop/cron-resourcemanager.erb"),
			}
		}
	}
}
