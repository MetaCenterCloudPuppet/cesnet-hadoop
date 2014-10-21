# == Class hadoop::nodemanager::service
# Namenode must be launched first if it is colocated with nodemanager
# (conflicting ports) (tested on hadoop 2.4.1).
#
# It works OK automatically when using from parent hadoop::service class.
#
class hadoop::nodemanager::service {
	service { "hadoop-nodemanager":
		ensure  => "running",
		enable => true,
		subscribe => [File["core-site.xml"], File["yarn-site.xml"]],
	}
}
