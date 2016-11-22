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
# == Class: tripleo::profile::base::neutron::plugins::plumgrid::plumgrid
#
# PLUMgrid Neutron profile for tripleo
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
class tripleo::profile::base::neutron::plugins::plumgrid::plumgrid (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step           = hiera('step'),
  $plumgrid_director_ips = hiera('controller_node_ips'),
  $internal_api_network = hiera('internal_api_network', 'undef'),
  $tenant_network = hiera('tenant_network', 'undef'),
  $internal_api_dev = hiera('internal_api_dev', 'undef'),
  $tenant_dev = hiera('tenant_dev', 'undef'),
  $plumgrid_repo_baseurl = hiera('plumgrid_repo_baseurl'),
  $plumgrid_repo_component = hiera('plumgrid_repo_component'),
  $plumgrid_md_ip = hiera('plumgrid_md_ip'),
) {

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ( $step >= 3 and $sync_db ) {

    if $internal_api_dev == 'undef' {
      $mgmt_dev = dev_for_network($internal_api_network)
    } else {
      $mgmt_dev = $internal_api_dev
    }

    if $tenant_dev == 'undef' {
      $fabric_dev = dev_for_network($tenant_network)
    } else {
      $fabric_dev = $tenant_dev
    }

    # Install PLUMgrid Director
    class{'plumgrid':
      plumgrid_ip => $plumgrid_director_ips,
      plumgrid_port => '8001',
      rest_port => '9180',
      mgmt_dev => $mgmt_dev,
      fabric_dev => $fabric_dev,
      repo_baseurl => "$plumgrid_repo_baseurl/yum",
      repo_component => $plumgrid_repo_component,
      lvm_keypath => '/var/lib/plumgrid/id_rsa.pub',
      md_ip => $plumgrid_md_ip,
      manage_repo => true,
      source_net=> $internal_api_network,
      dest_net => $internal_api_network,
      before => Class['::neutron'],
    }
  }
}
