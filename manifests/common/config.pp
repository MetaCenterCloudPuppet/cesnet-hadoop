class hadoop::common::config {
	file { "/etc/hadoop/core-site.xml":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "core-site.xml",
		content => template("hadoop/hadoop/core-site.xml.erb"),
	}

	file { "/etc/hadoop/slaves":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "slaves",
		content => template("hadoop/hadoop/slaves.erb"),
	}

	# for decommissioned data nodes
	exec { "touch-excludes" :
		command => "touch /etc/hadoop/excludes",
		path => "/bin:/usr/bin",
		creates => "/etc/hadoop/excludes",
	}

}
