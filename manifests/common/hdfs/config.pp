# == Class hadoop::common::hdfs::config
#
class hadoop::common::hdfs::config {
	file { "/etc/hadoop/hdfs-site.xml":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "hdfs-site.xml",
		content => template("hadoop/hadoop/hdfs-site.xml.erb"),
		require => [ Exec["touch-excludes"], File["slaves"] ],
	}

	# mapred user is required on name node,
	# it is created by hadoop-yarn package too, but we don't need yarn package with
	# all dependencies just for creating this user
	group { "mapred":
		ensure => present,
		system => true,
	}
	user { "mapred":
		ensure => present,
		comment => "Apache Hadoop MapReduce",
		password => "!!",
		shell => "/sbin/nologin",
		home => "/var/cache/hadoop-mapreduce",
		managehome => true,
		system => true,
		gid => "mapred",
		groups => [ "hadoop" ],
		require => [Group["mapred"]]
	}
}
