# == Class hadoop::config
#
# Format Hadoop Filesystem. When you need to re-format again, you must remove the datanode directory (and also clean all datanodes in cluster!).
#
# This class is called from hadoop.
#
class hadoop::format {
	# directory /var/lib/hadoop-hdfs/hdfs may be created by other daemons,
	# format command will create the namenode subdirectory
	exec { "hdfs-format":
		command => "sudo -u hdfs hdfs namenode -format ${hadoop::cluster_name} && rm -f /var/lib/hadoop-hdfs/.puppet-hdfs-root-created",
		creates => "/var/lib/hadoop-hdfs/hdfs/dfs/namenode",
		path => "/bin:/usr/bin",
	}
}
