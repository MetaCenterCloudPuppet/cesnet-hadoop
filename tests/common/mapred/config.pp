class{'::hadoop':
  realm => '',
}
contain hadoop::common::install
include ::hadoop::common::mapred::config

Class['hadoop::common::install'] -> Class['hadoop::common::mapred::config']
