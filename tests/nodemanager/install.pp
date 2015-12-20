class{'::hadoop':
  realm => '',
}
include ::hadoop::nodemanager::install
