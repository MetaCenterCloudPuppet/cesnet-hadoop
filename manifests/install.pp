# == Class hadoop::install
#
class hadoop::install {
  contain hadoop::common::install

  if $hadoop::daemon_journalnode { contain hadoop::journalnode::install }
  if $hadoop::daemon_namenode { contain hadoop::namenode::install }
  if $hadoop::daemon_resourcemanager { contain hadoop::resourcemanager::install }
  if $hadoop::daemon_historyserver { contain hadoop::historyserver::install }
  if $hadoop::daemon_datanode { contain hadoop::datanode::install }
  if $hadoop::daemon_nodemanager { contain hadoop::nodemanager::install }
  if $hadoop::frontend { contain hadoop::frontend::install }
  if $hadoop::nfs { contain hadoop::nfs::install }
}
