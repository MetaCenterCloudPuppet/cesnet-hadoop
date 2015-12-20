class{'::hadoop':
  realm => '',
}
include ::hadoop::resourcemanager::config
