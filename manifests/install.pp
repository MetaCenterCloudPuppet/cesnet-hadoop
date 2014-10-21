# == Class hadoop::install
#
class hadoop::install {
	include hadoop::common::install

	if $hadoop::daemon_namenode { include hadoop::namenode::install }
	if $hadoop::daemon_resourcemanager { include hadoop::resourcemanager::install }
	if $hadoop::daemon_historyserver { include hadoop::historyserver::install }
	if $hadoop::daemon_datanode { include hadoop::datanode::install }
	if $hadoop::daemon_nodemanager { include hadoop::nodemanager::install }
}
