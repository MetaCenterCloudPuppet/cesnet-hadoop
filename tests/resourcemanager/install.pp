class{'::hadoop':
  realm => '',
}
include ::hadoop::resourcemanager::install
