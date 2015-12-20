class{'::hadoop':
  realm => '',
}
include ::hadoop::nodemanager::config
