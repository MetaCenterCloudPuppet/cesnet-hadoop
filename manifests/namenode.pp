# == Class hadoop::namenode
#
# HDFS Name Node.
#
class hadoop::namenode {
  include ::hadoop::namenode::install
  include ::hadoop::namenode::config
  include ::hadoop::namenode::service

  Class['hadoop::namenode::install'] ->
  Class['hadoop::namenode::config'] ~>
  Class['hadoop::namenode::service'] ->
  Class['hadoop::namenode']
}
