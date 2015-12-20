class{'::hadoop':
  realm => '',
}
include ::hadoop::common::yarn::daemon
