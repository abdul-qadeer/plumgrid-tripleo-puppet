# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::neutron::plumgrid::conf::edge
#
# Plumgrid Neutron helper profile for edge (extra settings for compute, etc. roles)
#
# === Parameters
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plumgrid::conf::edge (
  $step                      = hiera('step'),

) {

  if $step >= 4 {

    # forward all ipv4 traffic
    # this is required for the vms to pass through the gateways public interface
    sysctl::value { 'net.ipv4.ip_forward': value => '1' }

    # ifc_ctl_pp needs to be invoked by root as part of the vif.py when a VM is powered on
    # Enable Network filetrs required by PLUMgrid
    file { '/etc/nova/rootwrap.d':
      ensure  => directory,
      owner   => root,
      group   => root,
    }

    file { '/etc/nova/rootwrap.d/plumgrid.filter':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => "# nova-rootwrap command filters for network nodes\n\n[Filters]\nifc_ctl: CommandFilter, /opt/pg/bin/ifc_ctl, root\nifc_ctl_pp: CommandFilter, /opt/pg/bin/ifc_ctl_pp, root\n",
      require => File["/etc/nova/rootwrap.d"],
    }

    file { '/etc/libvirt/qemu.conf':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0440',
      content => "cgroup_device_acl=[\"/dev/null\",\"/dev/full\",\"/dev/zero\",\"/dev/random\",\"/dev/urandom\",\"/dev/ptmx\",\"/dev/kvm\",\"/dev/kqemu\",\"/dev/rtc\",\"/dev/hpet\",\"/dev/net/tun\"]\nclear_emulator_capabilities=0\nuser=\"root\"\ngroup=\"root\"",
      notify => Service['libvirt'],
      before => Class['plumgrid'],
    }

    # Disable NetworkManager
    service { 'NetworkManager':
      ensure => stopped,
      enable => false,
      before => Service['openstack-nova-metadata-api'],
    }

    service { 'openstack-nova-metadata-api':
      ensure => running,
      enable => true,
      before => Class['plumgrid'],
    }

    class { firewall: }

    firewall {'001 nova metdata incoming':
      proto  => 'tcp',
      dport  => ["8775"],
      action => 'accept',
    }
  }
}
