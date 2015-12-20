class{'::hadoop':
  realm => '',
}
include ::hadoop::historyserver::install
