# Helpers class to ease use of puppetlabs/docker
#
# @param release_type The type of Docker to be managed
#   Possible values:
#     'redhat': RedHat packaged Docker
#     'ce':     Docker Community Edition
#     'ee':     Docker Enterprise Edition (Untested due to licensing)
#
#
# @param manage_sysctl Manage the sysctl rules required for container networking
#
# @param bridge_dev The network device Docker will use
#   This is only needed to check to see if it's possible to add the sysctl rules.
#
# @param default_options Default parameters for the upstream `docker` class.
#   If there is any friction here between this module and he upstream module,
#   it is a bug.
#
#   These parameters will be overwritten by $options if set there, so
#   please use that parameter instead.
#
# @param options Other options to be sent to the `docker` class.
#   @see https://github.com/puppetlabs/puppetlabs-docker/tree/1.0.2#usage
#
#   This parameter will overwrite and default setting in $default_options.
#
# @param iptables_docker_chain If using the SIMP iptables module, add the
#   `DOCKER` chain back when the iptables rules have been changed by Puppet.
#
# @author https://github.com/simp/pupmod-simp-simp_docker/graphs/contributors
#
class simp_docker (
  Simp_docker::Type $release_type,
  Boolean $manage_sysctl,
  String $bridge_dev,

  Hash $default_options,
  Optional[Hash] $options,

  Boolean $iptables_docker_chain = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
) {

  $_docker_bridge_up = ($bridge_dev in $facts['networking']['interfaces'].keys)
  if $manage_sysctl and $_docker_bridge_up {
    sysctl {
      default:
        before => Class['docker'];
      'net.bridge.bridge-nf-call-iptables':  value => 1 ;
      'net.bridge.bridge-nf-call-ip6tables': value => 1 ;
    }
  }

  if $iptables_docker_chain {
    include 'iptables'

    exec { 'Add docker chain back':
      command     => '/sbin/iptables -t filter -N DOCKER',
      refreshonly => true,
      subscribe   => Class['iptables']
    }
  }

  class { 'docker':
    * => $default_options[$release_type] + $options
  }
}
