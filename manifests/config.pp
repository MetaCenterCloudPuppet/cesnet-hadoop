# == Class hadoop::config
#
# This class is called from hadoop.
#
class hadoop::config {
	if $hadoop::realm {
		if $hadoop::daemon_namenode {
			file { "/etc/security/keytab/nn.service.keytab":
				owner => "hdfs",
				group => "hdfs",
				mode => "0400",
				alias => "nn.service.keytab",
				before => File["hdfs-site.xml"],
			}
		}
		if $hadoop::daemon_resourcemanager {
			file { "/etc/security/keytab/rm.service.keytab":
				owner => "yarn",
				group => "yarn",
				mode => "0400",
				alias => "rm.service.keytab",
				before => File["yarn-site.xml"],
			}
		}
		if $hadoop::daemon_historyserver {
			file { "/etc/security/keytab/jhs.service.keytab":
				owner => "mapred",
				group => "mapred",
				mode => "0400",
				alias => "jhs.service.keytab",
				before => File["mapred-site.xml"],
			}
		}
		if $hadoop::daemon_nodemanager {
			file { "/etc/security/keytab/nm.service.keytab":
				owner => "yarn",
				group => "yarn",
				mode => "0400",
				alias => "nm.service.keytab",
				before => File["yarn-site.xml"],
			}
		}
		if $hadoop::daemon_datanode {
			file { "/etc/security/keytab/dn.service.keytab":
				owner => "hdfs",
				group => "hdfs",
				mode => "0400",
				alias => "dn.service.keytab",
				before => File["hdfs-site.xml"],
			}
		}
	}

	file { "/etc/hadoop/core-site.xml":
		owner => "root",
		group => "root",
		mode => "0644",
		alias => "core-site.xml",
		content => template("hadoop/hadoop/core-site.xml.erb"),
	}

	if $hadoop::package_hdfs {
		# for decommissioned data nodes
		exec { "touch-excludes" :
			command => "touch /etc/hadoop/excludes",
			path => "/bin:/usr/bin",
			creates => "/etc/hadoop/excludes",
		}
		file { "/etc/hadoop/hdfs-site.xml":
			owner => "root",
			group => "root",
			mode => "0644",
			alias => "hdfs-site.xml",
			content => template("hadoop/hadoop/hdfs-site.xml.erb"),
			require => [ Exec["touch-excludes"], File["slaves"] ],
		}
	}

	if $hadoop::package_mapreduce {
		file { "/etc/hadoop/mapred-site.xml":
			owner => "root",
			group => "root",
			mode => "0644",
			alias => "mapred-site.xml",
			content => template("hadoop/hadoop/mapred-site.xml.erb"),
		}
	}

	if $hadoop::package_yarn {
		file { "/etc/hadoop/yarn-site.xml":
			owner => "root",
			group => "root",
			mode => "0644",
			alias => "yarn-site.xml",
			content => template("hadoop/hadoop/yarn-site.xml.erb"),
			require => [ Exec["touch-excludes"], File["slaves"] ],
		}
	}

	if $hadoop::package_hdfs or $hadoop::package_yarn {
		file { "/etc/hadoop/slaves":
			owner => "root",
			group => "root",
			mode => "0644",
			alias => "slaves",
			content => template("hadoop/hadoop/slaves.erb"),
		}
	}

	file { "/usr/local/bin/yellowelephant":
		mode => "0755",
		alias => "yellowelephant",
		content => template("hadoop/yellowelephant.erb"),
	}

	# mapred user is required on name node,
	# it is created by hadoop-yarn package, but we don't need yarn package with
	# all dependencies just for creating this user
	if $hadoop::mapred_user and !$hadoop::package_yarn {
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
		$mapred_user_dep = User["mapred"]
	} else {
		$mapred_user_dep = Package["hadoop-yarn"]
	}
}
