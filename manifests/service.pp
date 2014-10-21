# == Class hadoop::service
#
# This class is meant to be called from hadoop.
# It ensure the services are running.
#
class hadoop::service {
	if $hadoop::daemon_namenode {
		include hadoop::namenode::service
	}

	if $hadoop::daemon_resourcemanager {
		include hadoop::resourcemanager::service
	}

	if $hadoop::daemon_historyserver {
		include hadoop::historyserver::service

		# namenode should be launched first if it is colocated with historyserver
		# (just cosmetics, some initial exceptions in logs) (tested on hadoop 2.4.1)
		if $hadoop::daemon_namenode {
			Class["hadoop::namenode::service"] -> Class["hadoop::historyserver::service"]
		}
	}

	if $hadoop::daemon_nodemanager {
		include hadoop::nodemanager::service

		# namenode must be launched first if it is colocated with nodemanager
		# (conflicting ports) (tested on hadoop 2.4.1)
		if $hadoop::daemon_namenode {
			Class["hadoop::namenode::service"] -> Class["hadoop::nodemanager::service"]
		}
	}

	if $hadoop::daemon_datanode {
		include hadoop::datanode::service
	}
}
