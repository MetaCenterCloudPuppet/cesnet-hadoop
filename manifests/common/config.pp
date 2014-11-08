class hadoop::common::config {
	file { "/etc/hadoop/core-site.xml":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "core-site.xml",
		content => template("hadoop/hadoop/core-site.xml.erb"),
	}
}
