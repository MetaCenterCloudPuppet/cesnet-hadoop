# == Class hadoop::service
#
# This class is meant to be called from hadoop.
# It ensure the services are running.
#
class hadoop::service {
	if $hadoop::daemon_namenode {
		contain hadoop::namenode::service
	}

	if $hadoop::daemon_resourcemanager {
		contain hadoop::resourcemanager::service

		# namenode should be launched first if it is colocated with historyserver
		# (just cosmetics, some initial exceptions in logs) (tested on hadoop 2.4.1)
		if $hadoop::daemon_namenode {
			Class["hadoop::namenode::service"] -> Class["hadoop::resourcemanager::service"]
		}

		# any datanode needs to be launched when state-store feature is enabled,
		# so rather always start it when colocated with resource manager
		if $hadoop::daemon_datanode and $hadoop::features["rmstore"] {
			Class["hadoop::datanode::service"] -> Class["hadoop::resourcemanager::service"]
		}
	}

	if $hadoop::daemon_historyserver {
		contain hadoop::historyserver::service

		# namenode should be launched first if it is colocated with historyserver
		# (just cosmetics, some initial exceptions in logs) (tested on hadoop 2.4.1)
		if $hadoop::daemon_namenode {
			Class["hadoop::namenode::service"] -> Class["hadoop::historyserver::service"]
		}
	}

	if $hadoop::daemon_nodemanager {
		contain hadoop::nodemanager::service

		# namenode must be launched first if it is colocated with nodemanager
		# (conflicting ports) (tested on hadoop 2.4.1)
		if $hadoop::daemon_namenode {
			Class["hadoop::namenode::service"] -> Class["hadoop::nodemanager::service"]
		}
	}

	if $hadoop::daemon_datanode {
		contain hadoop::datanode::service

		if $hadoop::daemon_namenode {
			Class["hadoop::namenode::service"] -> Class["hadoop::datanode::service"]
		}
	}

	if $hadoop::frontend { contain hadoop::frontend::service }
}
