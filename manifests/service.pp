# == Class hadoop::service
#
# This class is meant to be called from hadoop.
# It ensure the services are running.
#
class hadoop::service {
  if $hadoop::daemon_journalnode { contain hadoop::journalnode::service }
  if $hadoop::daemon_namenode { contain hadoop::namenode::service }
  if $hadoop::daemon_resourcemanager { contain hadoop::resourcemanager::service }
  if $hadoop::daemon_historyserver { contain hadoop::historyserver::service }
  if $hadoop::daemon_nodemanager { contain hadoop::nodemanager::service }
  if $hadoop::daemon_datanode { contain hadoop::datanode::service }
  if $hadoop::frontend { contain hadoop::frontend::service }
  if $hadoop::nfs { contain hadoop::nfs::service }
}
