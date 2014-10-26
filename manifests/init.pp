# == Class: hadoop
#
# Setup Hadoop Cluster. Security and Kerberos are suported.
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
#   Kerberos realm. Empty string disables Kerberos authentication. Required parameter.
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

	if $yarn_hostname and !$rm_hostname { $rm_hostname = $yarn_hostname }

	if $fqdn == $hdfs_hostname {
		$daemon_namenode = 1
		$mapred_user = 1

	}

	if $fqdn == $yarn_hostname {
		$daemon_resourcemanager = 1
		$daemon_historyserver = 1
	}

	if member($slaves, $fqdn) {
		$daemon_nodemanager = 1
		$daemon_datanode = 1
	}

	class { 'hadoop::install': } ->
	class { 'hadoop::config': } ~>
	class { 'hadoop::service': } ->
	Class['hadoop']

	# XXX: helper administrator script, move somewere else
	file { "/usr/local/bin/yellowelephant":
		mode => "0755",
		alias => "yellowelephant",
		content => template("hadoop/yellowelephant.erb"),
		require => Class['hadoop::config'],
	}
}
