# == Class: hadoop
#
# Setup Hadoop Cluster. Security and Kerberos are suported (TODO: still some problems to resolve...).
#
# === Parameters
#
# [*hdfs_hostname*] (localhost)
#   Hadoop Filesystem Name Node machine.
#
# [*yarn_hostname*] (localhost)
#   Yarn machine (with Resource Manager and Job History services).
#
# [*slaves*] (localhost)
#   Array of slave node hostnames.
#
# [*replication*] (1)
#   Number of replicas.
#
# [*realm*]
#   Kerberos realm. Required parameter. TODO: empty value for disabling
#
class hadoop (
	$hdfs_hostname = $params::hdfs_hostname,
	$yarn_hostname = $params::yarn_hostname,
	$slaves = $params::slaves,
	$cluster_name = $params::cluster_name,
	$replication = $params::replication,
	$realm,
) inherits hadoop::params {
	include 'stdlib'

	if $fqdn == $hdfs_hostname {
		$package_hdfs = 1
		$package_native = 1
		$daemon_namenode = 1
		$mapred_user = 1

	}

	if $fqdn == $yarn_hostname {
		if (!$package_mapreduce) { $package_mapreduce = 1 }
		if (!$package_native) { $package_native = 1 }
		if (!$package_yarn) { $package_yarn = 1 }
		$daemon_resourcemanager = 1
		$daemon_historyserver = 1
	}

	if member($slaves, $fqdn) {
		if (!$package_hdfs) { $package_hdfs = 1 }
		if (!$package_native) { $package_native = 1 }
		if (!$package_yarn) { $package_yarn = 1 }
		$daemon_nodemanager = 1
		$daemon_datanode = 1
	}

	# configure files in dependent packages too
	if ($package_mapreduce or $package_yarn) and !$package_hdfs { $package_hdfs = 1 }
	if $package_yarn and !$package_mapreduce { $package_mapreduce = 1 }

	class { 'hadoop::install': } ->
	class { 'hadoop::config': } ~>
	class { 'hadoop::service': } ->
	Class['hadoop']
}
