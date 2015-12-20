class{'::hadoop':
  realm => '',
}
include ::hadoop::common::hdfs::daemon
