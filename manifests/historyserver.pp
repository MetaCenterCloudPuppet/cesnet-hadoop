# == Class hadoop::historyserver
#
# MapReduce Job History Server.
#
class hadoop::historyserver {
  include ::hadoop::historyserver::install
  include ::hadoop::historyserver::config
  include ::hadoop::historyserver::service

  Class['hadoop::historyserver::install'] ->
  Class['hadoop::historyserver::config'] ~>
  Class['hadoop::historyserver::service'] ->
  Class['hadoop::historyserver']
}
