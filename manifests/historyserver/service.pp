# == Class hadoop::historyserver::service
#
# Namenode should be launched first if it is colocated with historyserver
# (just cosmetics, some initial exceptions in logs) (tested on hadoop 2.4.1).
#
# It works OK automatically when using from parent hadoop::service class.
#
class hadoop::historyserver::service {
	service { "hadoop-historyserver":
		ensure  => "running",
		enable => true,
		subscribe => [File["core-site.xml"], File["yarn-site.xml"]],
	}
}
