# == Class hadoop::zkfc
#
# HDFS Zookeeper/Failover Controller.
#
class hadoop::zkfc {
  include '::hadoop::zkfc::install'
  include '::hadoop::zkfc::config'
  include '::hadoop::zkfc::service'

  Class['hadoop::zkfc::install'] ->
  Class['hadoop::zkfc::config'] ~>
  Class['hadoop::zkfc::service'] ->
  Class['hadoop::zkfc']
}
