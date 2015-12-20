class{'::hadoop':
  realm => '',
}
include ::hadoop::journalnode::install
