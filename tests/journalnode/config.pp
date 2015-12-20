class{'::hadoop':
  realm => '',
}
include ::hadoop::journalnode::config
