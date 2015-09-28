# == Class hadoop::resourcemanager
#
class hadoop::resourcemanager {
  include ::hadoop::resourcemanager::install
  include ::hadoop::resourcemanager::config
  include ::hadoop::resourcemanager::service

  Class['hadoop::resourcemanager::install'] ->
  Class['hadoop::resourcemanager::config'] ~>
  Class['hadoop::resourcemanager::service'] ->
  Class['hadoop::resourcemanager']
}
