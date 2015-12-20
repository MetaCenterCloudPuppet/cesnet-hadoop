class{'::hadoop':
  realm => '',
}
include ::hadoop::datanode::config
