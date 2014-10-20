# == Class hadoop::service
#
# This class is meant to be called from hadoop.
# It ensure the services are running.
#
class hadoop::service {
	if $hadoop::daemon_namenode {
		class { "format":
			before => Service["hadoop-namenode"],
		}
		service { "hadoop-namenode":
			ensure  => "running",
			enable => true,
			subscribe => [File["core-site.xml"], File["hdfs-site.xml"]],
		}
		class { "create_dirs":
			require => [Service["hadoop-namenode"], Class["format"]],
			subscribe => [Class["format"], $hadoop::config::mapred_user_dep],
		}
	}

	if $hadoop::daemon_resourcemanager {
		service { "hadoop-resourcemanager":
			ensure  => "running",
			enable => true,
			subscribe => [File["core-site.xml"], File["yarn-site.xml"]],
		}
	}

	if $hadoop::daemon_historyserver {
		# namenode should be launched first if it is colocated with historyserver
		# (just cosmetics, some initial exceptions in logs) (tested on hadoop 2.4.1)
		if $hadoop::daemon_namenode {
			$daemon_historyserver_deps = Service["hadoop-namenode"]
		} else {
			# dirty hack - can't be empty
			$daemon_historyserver_deps = File["core-site.xml"]
		}
		service { "hadoop-historyserver":
			ensure  => "running",
			enable => true,
			require => [$daemon_historyserver_deps ],
			subscribe => [File["core-site.xml"], File["yarn-site.xml"]],
		}
	}

	if $hadoop::daemon_nodemanager {
		# namenode must be launched first if it is colocated with nodemanager
		# (conflicting ports) (tested on hadoop 2.4.1)
		if $hadoop::daemon_namenode {
			$daemon_nodemanager_deps = Service["hadoop-namenode"]
		} else {
			# dirty hack - can't be empty
			$daemon_nodemanager_deps = File["core-site.xml"]
		}
		service { "hadoop-nodemanager":
			ensure  => "running",
			enable => true,
			require => [$daemon_nodemanager_deps],
			subscribe => [File["core-site.xml"], File["yarn-site.xml"]],
		}
	}

	if $hadoop::daemon_datanode {
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
}
