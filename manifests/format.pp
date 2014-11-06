# == Class hadoop::format
#
# Format Hadoop Filesystem. When you need to re-format again, you must remove the datanode directory (and also clean all datanodes in cluster!).
#
# This class is called from hadoop.
#
class hadoop::format {
	$dirs = map($hadoop::hdfs_dirs) |$dir| { regsubst($dir, "^file://", "") }

	file { $dirs:
		ensure => directory,
		owner => 'hdfs',
		group => 'hadoop',
		mode => '0755',
	}

	->

	# 1) directory /var/lib/hadoop-hdfs/hdfs may be created by other
	#    daemons, format command will create the namenode subdirectory
	# 2) prefix can be different and/or replicated anyway
	exec { "hdfs-format":
		command => "sudo -u hdfs hdfs namenode -format ${hadoop::cluster_name} && rm -f /var/lib/hadoop-hdfs/.puppet-hdfs-root-created && touch /var/lib/hadoop-hdfs/.puppet-hdfs-formatted",
		creates => "/var/lib/hadoop-hdfs/.puppet-hdfs-formatted",
		path => "/bin:/usr/bin",
	}
}
