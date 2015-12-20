class{'::hadoop':
  realm => '',
}
include ::hadoop::zkfc::install
