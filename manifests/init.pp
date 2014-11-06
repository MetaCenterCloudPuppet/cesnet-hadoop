# == Class: hadoop
#
# Setup Hadoop Cluster. Security and Kerberos are supported.
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
# [*frontends*]
#   Array of frontend hostnames. Used *slaves* by default.
#
# [*replication*] (1)
#   Number of replicas.
#
# [*cluster_name*] ("")
#   Name of the cluster, used during initial formatting of HDFS.
#
# [*realm*]
#   Kerberos realm. Required parameter, empty string disables Kerberos authentication.
#
# [*namenode_hostname*] (undef)
#   Name Node machine. Used *hdfs_hostname* by default.
#
# [*resourcemanager_hostname*] (undef)
#   Resource Manager machine. Used *yarn_hostname* by default.
#
# [*historyserver_hostname*] (undef)
#   History Server machine. Used *yarn_hostname* by default.
#
# [*nodemanager_hostnames*] (undef)
#   Array of Node Manager machines. Used *slaves* by default.
#
# [*datanodes_hostnames*] (undef)
#   Array of Data Node machines. Used *slaves* by default.
#
# [*hdfs_dirs*] (["file:///var/lib/hadoop-hdfs"])
#  Directory prefixes to store the data.
#    - namenode:
#	- name table (fsimage) and DFS data blocks
#	- /${user.name}/dfs/namenode suffix is always added
#       - If there is multiple directories, then the name table is replicated in all of the directories, for redundancy.
#    - datanode:
#	- DFS data blocks
#	- /${user.name}/dfs/datanode suffix is always added
#	- If there is multiple directories, then data will be stored in all directories, typically on different devices.
#  When adding a new directory, you need to replicate the contents from some of the other ones. Or set dfs.namenode.name.dir.restore to true and create NEW_DIR/hdfs/dfs/namenode with proper owners.
#
#
class hadoop (
	$hdfs_hostname = $params::hdfs_hostname,
	$yarn_hostname = $params::yarn_hostname,
	$slaves = $params::slaves,
	$frontends = [],
	$cluster_name = $params::cluster_name,
	$replication = $params::replication,
	$realm,

	$namenode_hostname = undef,
	$resourcemanager_hostname = undef,
	$historyserver_hostname = undef,
	$nodemanager_hostnames = undef,
	$datanode_hostnames = undef,

	$hdfs_dirs = $params::hdfs_dirs,
) inherits hadoop::params {
	include 'stdlib'

	# detailed deployment bases on convenient parameters
	if $namenode_hostname { $nn_hostname = $namenode_hostname }
	else { $nn_hostname = $hdfs_hostname }
	if $resourcemanager_hostname { $rm_hostname = $resourcemanager_hostname }
	else { $rm_hostname = $yarn_hostname }
	if $historyserver_hostname { $hs_hostname = $historyserver_hostname }
	else { $hs_hostname = $yarn_hostname }
	if $nodemanager_hostnames { $nm_hostnames = $nodemanager_hostnames }
	else { $nm_hostnames = $slaves }
	if $datanode_hostnames { $dn_hostnames = $datanode_hostnames }
	else { $dn_hostnames = $slaves }
	if $frontends { $frontend_hostnames = $frontends }
	else { $frontend_hostnames = $slaves }

	if $fqdn == $nn_hostname {
		$daemon_namenode = 1
		$mapred_user = 1

	}

	if $fqdn == $rm_hostname {
		$daemon_resourcemanager = 1
	}

	if $fqdn == $hs_hostname {
		$daemon_historyserver = 1
	}

	if member($nm_hostnames, $fqdn) {
		$daemon_nodemanager = 1
	}

	if member($dn_hostnames, $fqdn) {
		$daemon_datanode = 1
	}

	if member($frontend_hostnames, $fqdn) {
		$frontend = 1
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
