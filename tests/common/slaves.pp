class{'::hadoop':
  realm => '',
}
include ::hadoop::common::slaves
