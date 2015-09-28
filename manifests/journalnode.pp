# == Class hadoop::journalnode
#
# HDFS Journal Node used for Quorum Journal Manager. This is needed only when using two Name Nodes with HA. The alternative is to use NFS shared storage.
#
# Requires configured https on HDFS.
#
class hadoop::journalnode {
  include ::hadoop::journalnode::install
  include ::hadoop::journalnode::config
  include ::hadoop::journalnode::service

  if $hadoop::realm and $hadoop::realm != '' and !$hadoop::https {
    warning('https is required for using journal nodes')
  }

  Class['hadoop::journalnode::install'] ->
  Class['hadoop::journalnode::config'] ~>
  Class['hadoop::journalnode::service'] ->
  Class['hadoop::journalnode']
}
