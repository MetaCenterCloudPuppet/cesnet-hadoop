class{'::hadoop':
  realm => '',
}
include ::hadoop::zkfc::config
