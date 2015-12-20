class{'::hadoop':
  realm => '',
}
include ::hadoop::historyserver::config
