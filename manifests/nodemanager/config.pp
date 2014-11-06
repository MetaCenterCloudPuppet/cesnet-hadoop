# == Class hadoop::nodemanager::config
#
class hadoop::nodemanager::config {
	contain hadoop::common::config
	contain hadoop::common::hdfs::config
	contain hadoop::common::mapred::config
	contain hadoop::common::yarn::config

	if $hadoop::daemon_nodemanager and $hadoop::realm {
		file { "/etc/security/keytab/nm.service.keytab":
			owner => "yarn",
			group => "yarn",
			mode => "0400",
			alias => "nm.service.keytab",
			before => File["yarn-site.xml"],
		}
	}

	file { "/etc/hadoop/container-executor.cfg":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "container-executor.cfg",
		content => template("hadoop/hadoop/container-executor.cfg.erb"),
	}

	# fix Fedora startup - launch under group yarn
	file { "/etc/systemd/system/hadoop-nodemanager.service":
		owner => "root",
		group => "root",
		alias => "hadoop-nodemanager.service",
		source => "puppet:///modules/hadoop/hadoop-nodemanager.service",
	}
	~>
	# fix Fedora startup - reload systemd after changes
	exec { "nodemanager-systemctl-daemon-reload":
		command => "systemctl daemon-reload",
		path => "/sbin:/usr/sbin:/bin:/usr/bin",
		refreshonly => true,
	}
}
