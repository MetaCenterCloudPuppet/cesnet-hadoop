# == Class hadoop::nodemanager
#
class hadoop::nodemanager {
  include 'hadoop::nodemanager::install'
  include 'hadoop::nodemanager::config'
  include 'hadoop::nodemanager::service'

  Class['hadoop::nodemanager::install'] ->
  Class['hadoop::nodemanager::config'] ~>
  Class['hadoop::nodemanager::service'] ->
  Class['hadoop::nodemanager']
}
