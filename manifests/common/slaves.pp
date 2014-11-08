# == Class hadoop::common::slaves
#
# Maintain list of slave nodes. List of excluded nodes is not changed, only ensured the file exists.
#
# When changing slaves, daemons are neigher restarted or refreshed!
#
# After any change you need to instruct hdfs and yarn to refresh slaves:
# 1) namenode machine: hdfs dfsadmin -refreshNodes
# 2) resourcemanager machine: yarn rmadmin -refreshNodes
#
class hadoop::common::slaves {
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
