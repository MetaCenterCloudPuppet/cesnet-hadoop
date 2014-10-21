# == Class hadoop::datanode::service
#
class hadoop::datanode::service {
	# TODO: needs also a patch for hadoop-daemon.sh
	# fix Fedora startup - environment
	file { "/etc/sysconfig/hadoop-datanode":
		owner => "root",
		group => "root",
		alias => "sysconfig-hadoop-datanode",
		source => "puppet:///modules/hadoop/hadoop-datanode",
	}
	# fix Fedora startup - launch under the root
	file { "/etc/systemd/system/hadoop-datanode.service":
		owner => "root",
		group => "root",
		alias => "hadoop-datanode.service",
		source => "puppet:///modules/hadoop/hadoop-datanode.service",
	}
	# fix Fedora startup - reload systemd after changes
	# XXX: should launch only after service file change,
	#      but this is workaround for bug in Fedora which needs to be fixed anyway
	exec { "systemctl-daemon-reload":
		command => "systemctl daemon-reload",
		path => "/sbin:/usr/sbin:/bin:/usr/bin",
		require => [File["sysconfig-hadoop-datanode"], File["hadoop-datanode.service"]],
		subscribe => File["hadoop-datanode.service"],
	}
	service { "hadoop-datanode":
		ensure  => "running",
		enable => true,
		require => [Exec["systemctl-daemon-reload"]],
		subscribe => [File["core-site.xml"], File["hdfs-site.xml"], File["sysconfig-hadoop-datanode"], File["hadoop-datanode.service"]],
	}
}
