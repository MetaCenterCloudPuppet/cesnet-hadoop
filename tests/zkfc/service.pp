class{'::hadoop':
  realm => '',
}
include ::hadoop::common::config
include ::hadoop::common::hdfs::config
include ::hadoop::zkfc::service
