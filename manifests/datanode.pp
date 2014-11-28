# == Class hadoop::datanode
#
class hadoop::datanode {
  include 'hadoop::datanode::install'
  include 'hadoop::datanode::config'
  include 'hadoop::datanode::service'

  Class['hadoop::datanode::install'] ->
  Class['hadoop::datanode::config'] ~>
  Class['hadoop::datanode::service'] ->
  Class['hadoop::datanode']
}
