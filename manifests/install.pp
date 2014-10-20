# == Class hadoop::install
#
class hadoop::install {
	package { "hadoop-common": }
	if $hadoop::package_hdfs { package { "hadoop-hdfs": } }
	if $hadoop::package_mapreduce { package { "hadoop-mapreduce": } }
	# all services require hadoop native libraries (otherwise they are slow and warnings are generated)
	if $hadoop::package_native { package { "hadoop-common-native": } }
	if $hadoop::package_yarn { package { "hadoop-yarn": } }
	if $hadoop::realm { package { "krb5-workstation": } }
}
