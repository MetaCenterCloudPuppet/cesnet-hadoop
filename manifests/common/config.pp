# == Class: hadoop::common::config
#
# Setup the part common for all nodes - core-site.xml.
#
class hadoop::common::config {
	file { "/etc/hadoop/core-site.xml":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "core-site.xml",
		content => template("hadoop/hadoop/core-site.xml.erb"),
	}
}
