class{'::hadoop':
  realm => '',
}
include ::hadoop::namenode::config
