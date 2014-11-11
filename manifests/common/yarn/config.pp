# == Class: hadoop::common::yarn::config
#
# Setup the "yarn part" on the nodes. This class is used for example for historyserver, resourcemanager, nodemanagers or frontends.
#
class hadoop::common::yarn::config {
	include hadoop::common::slaves

	file { "/etc/hadoop/yarn-site.xml":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "yarn-site.xml",
		content => template("hadoop/hadoop/yarn-site.xml.erb"),
		require => [ Exec["touch-excludes"], File["slaves"] ],
	}
}
