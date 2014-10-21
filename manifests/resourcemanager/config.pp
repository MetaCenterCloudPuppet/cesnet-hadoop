# == Class hadoop::resourcemanager::config
#
class hadoop::resourcemanager::config {
	include hadoop::common::config
	include hadoop::common::mapred::config
	include hadoop::common::yarn::config

	if $hadoop::realm {
		if $hadoop::daemon_resourcemanager {
			file { "/etc/security/keytab/rm.service.keytab":
				owner => "yarn",
				group => "yarn",
				mode => "0400",
				alias => "rm.service.keytab",
			}
		}
	}
}
