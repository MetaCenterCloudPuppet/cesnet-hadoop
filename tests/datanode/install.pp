class{'::hadoop':
  realm => '',
}
include ::hadoop::datanode::install
