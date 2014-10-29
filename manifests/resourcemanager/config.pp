# == Class hadoop::resourcemanager::config
#
class hadoop::resourcemanager::config {
	contain hadoop::common::config
	contain hadoop::common::mapred::config
	contain hadoop::common::yarn::config

	if $hadoop::daemon_resourcemanager and $hadoop::realm {
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
