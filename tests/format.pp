class{'::hadoop':
  realm => '',
}
include ::hadoop::namenode::config
include ::hadoop::format
