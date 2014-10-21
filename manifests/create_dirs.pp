# == Class hadoop::create_dirs
#
# Create root directory layout at Hadoop Filesystem. Take care also for Kerberos ticket inicialization and destruction, when realm is specified.
#
# Requirements: HDFS needs to be formatted and namenode service running.
#
# This class is called from hadoop::service.
#
class hadoop::create_dirs {
	$realm = $hadoop::realm

	exec { "hdfs-kinit":
		command => "runuser hdfs -s /bin/bash /bin/bash -c \"kinit -k nn/$fqdn@$realm -t /etc/security/keytab/nn.service.keytab\"",
		path => "/sbin:/usr/sbin:/bin:/usr/bin",
		onlyif => "test -n \"$realm\"",
		creates => "/var/lib/hadoop-hdfs/.puppet-hdfs-root-created",
	}
	exec { "hdfs-dirs":
		command => "/usr/sbin/hdfs-create-dirs && touch /var/lib/hadoop-hdfs/.puppet-hdfs-root-created",
		path => "/sbin:/usr/sbin:/bin:/usr/bin",
		creates => "/var/lib/hadoop-hdfs/.puppet-hdfs-root-created",
		require => Exec["hdfs-kinit"],
	}
	exec { "hdfs-kdestroy":
		command => "runuser hdfs -s /bin/bash /bin/bash -c \"kdestroy\"",
		path => "/sbin:/usr/sbin:/bin:/usr/bin",
		onlyif => "test -n \"$realm\"",
		creates => "/var/lib/hadoop-hdfs/.puppet-hdfs-root-created",
		require => Exec["hdfs-dirs"],
	}
}
