class hadoop::common::yarn::config {
	file { "/etc/hadoop/yarn-site.xml":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "yarn-site.xml",
		content => template("hadoop/hadoop/yarn-site.xml.erb"),
		require => [ Exec["touch-excludes"], File["slaves"] ],
	}
}
