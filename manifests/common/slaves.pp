# == Class hadoop::common::slaves
#
# Maintain list of slave nodes. List of excluded nodes is not changed, only ensured the file exists.
#
# When changing slaves, daemons are neigher restarted or refreshed!
#
# After any change you need to instruct hdfs and yarn to refresh slaves:
# 1) namenode machine: hdfs dfsadmin -refreshNodes
# 2) resourcemanager machine: yarn rmadmin -refreshNodes
#
class hadoop::common::slaves {
  if $hadoop::slaves and (!$hadoop::datanode_hostnames or !$hadoop::nodemanager_hostnames) {
    file { "${hadoop::confdir}/slaves":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      alias   => 'slaves',
      content => template('hadoop/hadoop/slaves.erb'),
    }
  } else {
    file { "${hadoop::confdir}/slaves":
      ensure => 'absent',
    }
  }

  # for decommissioned data nodes
  exec { 'touch-excludes' :
    command => "touch ${hadoop::confdir}/excludes",
    path    => '/bin:/usr/bin',
    creates => "${hadoop::confdir}/excludes",
  }
}
