# == Class hadoop::config
#
# This class is called from hadoop.
#
class hadoop::config {
	include hadoop::common::config

	if $hadoop::daemon_namenode {
		include hadoop::namenode::config
	}

	if $hadoop::daemon_resourcemanager {
		include hadoop::resourcemanager::config
	}

	if $hadoop::daemon_historyserver {
		include hadoop::historyserver::config
	}

	if $hadoop::daemon_nodemanager {
		include hadoop::nodemanager::config
	}

	if $hadoop::daemon_datanode {
		include hadoop::datanode::config
	}

}
