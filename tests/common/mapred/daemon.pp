class{'::hadoop':
  realm => '',
}
include ::hadoop::common::mapred::daemon
