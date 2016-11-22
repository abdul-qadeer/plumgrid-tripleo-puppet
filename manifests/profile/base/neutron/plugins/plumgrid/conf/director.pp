# Copyright 2016 PLUMgrid, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::neutron::plugins::plumgrid::conf::director
#
# Plumgrid Neutron helper profile for director (extra settings for controllers, etc. roles)
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plugins::plumgrid::conf::director (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step           = hiera('step'),
  $plumgrid_repo_baseurl = hiera('plumgrid_repo_baseurl'),
  $plumgrid_repo_component = hiera('plumgrid_repo_component'),
  $plumgrid_nova_metaconfig = hiera('plumgrid_nova_metaconfig'),
  $plumgrid_reverse_flow_tap = hiera('plumgrid_reverse_flow_tap'),
  $user_domain_name = 'Default',
  $project_domain_name = 'Default',
  $plumgrid_nova_endpoint_type = hiera('plumgrid_nova_endpoint_type'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::neutron

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    include ::neutron::plugins::plumgrid

    # Neutron class definitions
    class{'::neutron':
      service_plugins => [],
    }

    include ::neutron::config

    class { '::neutron::server' :
      sync_db            => $sync_db,
      manage_service     => false,
      enabled            => false,
      api_workers        => '4',
    }

    # Disable NetworkManager
    service { 'NetworkManager':
      ensure => stopped,
      enable => false,
    }

    yumrepo { 'plumgrid-openstack':
      baseurl => "$plumgrid_repo_baseurl/openstack/rpm/$plumgrid_repo_component/newton/x86_64",
      descr => 'PLUMgrid Openstack Repo',
      enabled => 1,
      gpgcheck => 1,
      gpgkey => "$plumgrid_repo_baseurl/openstack/rpm/GPG-KEY",
      before => Class['::neutron::plugins::plumgrid'],
    }

    # Configure new parameters for pglib
    exec { 'pg_lib nova_metaconfig':
      command => "openstack-config --set /etc/neutron/plugins/plumgrid/plumlib.ini PLUMgridLibrary nova_metaconfig $plumgrid_nova_metaconfig",
      path    => [ '/usr/local/bin/', '/bin/' ],
      require => Class['::neutron::plugins::plumgrid'],
    }

    # Configure new parameters for pglib
    exec { 'pg_lib enable_reverse_flow':
      command => "openstack-config --set /etc/neutron/plugins/plumgrid/plumlib.ini PLUMgridLibrary enable_reverse_flow_tap $plumgrid_reverse_flow_tap",
      path    => [ '/usr/local/bin/', '/bin/' ],
      require => Class['::neutron::plugins::plumgrid'],
    }

    # Configure new parameters for python-keystoneclient versions 1.7.0 and above
    exec { 'keystone_authtoken user_domain_name config':
      command => "openstack-config --set /etc/neutron/plugins/plumgrid/plumlib.ini keystone_authtoken user_domain_name ${user_domain_name}",
      path    => [ '/usr/local/bin/', '/bin/' ],
      require => Class['::neutron::plugins::plumgrid'],
    }

    # Configure new parameters for python-keystoneclient versions 1.7.0 and above
    exec { 'keystone_authtoken project_domain_name config':
      command => "openstack-config --set /etc/neutron/plugins/plumgrid/plumlib.ini keystone_authtoken project_domain_name ${project_domain_name}",
      path    => [ '/usr/local/bin/', '/bin/' ],
      require => Class['::neutron::plugins::plumgrid'],
    }

    # Configure new parameters for pglib
    exec { 'pg_lib nova_endpoint_type':
      command => "openstack-config --set /etc/neutron/plugins/plumgrid/plumlib.ini Nova endpoint_type $plumgrid_nova_endpoint_type",
      path    => [ '/usr/local/bin/', '/bin/' ],
      require => Class['::neutron::plugins::plumgrid'],
    }
  }
}
