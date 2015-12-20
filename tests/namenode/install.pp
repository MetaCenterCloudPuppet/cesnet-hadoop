class{'::hadoop':
  realm => '',
}
include ::hadoop::namenode::install
