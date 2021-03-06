# Installs and parameters puppet client
class puppet::client (
  $facter_version = '',
  $puppet_client_version = ''
  ) {
  include debian
  include puppet::common

  $user_facter_version = $facter_version ? {
    ''      => latest,
    default => $facter_version,
  }

  package {'facter':
    ensure  => $user_facter_version,
    require => Package['lsb-release'],
    tag     => 'install-puppet',
  }

  $use_puppet_client_version = $puppet_client_version ? {
    ''      => latest,
    default => $puppet_client_version,
  }

  package { 'puppet':
    ensure  => $use_puppet_client_version,
    require => Package['facter'],
    tag     => 'install-puppet',
  }

  if $debian::lenny {
    apt::preferences { 'puppet':
      package  => puppet,
      pin      => 'release a=lenny-backports',
      priority => 999,
      before   => Package[puppet],
      require  => [Apt::Sources_List['lenny-backports'], Apt::Preferences['puppet-common']]
    }
  }

  if $debian::squeeze {
    apt::preferences { 'puppet':
      package  => puppet,
      pin      => 'release a=squeeze-backports',
      priority => 999,
      before   => Package[puppet],
      require  => [Apt::Sources_List['squeeze-backports'], Apt::Preferences['puppet-common']]
    }
  }

  $lsb_release_pkg = $::operatingsystem ? {
    'Debian' => 'lsb-release',
    'Ubuntu' => 'lsb-release',
    'Redhat' => 'redhat-lsb',
    'fedora' => 'redhat-lsb',
  }

  package {'lsb-release':
    ensure => present,
    name   => $lsb_release_pkg,
  }

  service { 'puppet':
    ensure    => stopped,
    enable    => false,
    hasstatus => false,
    tag       => 'install-puppet',
    pattern   => 'ruby /usr/sbin/puppetd -w',
    # make sure the puppet cron is installed before the service is stopped
    #require   => [ Cron[puppetd], File['/etc/puppet/puppet.conf'] ]
    require   => Cron[puppetd]
  }

  user { 'puppet':
    ensure  => present,
    require => Package['puppet'],
  }

  file {'/etc/puppet/puppetd.conf': ensure => absent }

#  file { '/etc/puppet/puppet.conf':
#    source => [ "puppet:///files/puppet/client/${fqdn}/puppet.conf",
#      "puppet:///files/puppet/client/puppet.conf",
#      "puppet:///modules/puppet/client/puppet.conf" ],
#    owner  => 'root',
#    group  => 0,
#    mode   => '0644';
#  }
#
#  file { '/etc/puppet/namespaceauth.conf':
#    source => [
#      "puppet:///files/puppet/client/${fqdn}/namespaceauth.conf",
#      "puppet:///files/puppet/client/namespaceauth.conf.${operatingsystem}",
#      "puppet:///files/puppet/client/namespaceauth.conf",
#      "puppet:///modules/puppet/client/namespaceauth.conf.${operatingsystem}",
#      "puppet:///modules/puppet/client/namespaceauth.conf" ],
#    owner  => root,
#    group  => 0,
#    mode   => '0600';
#  }

  file {'/var/run/puppet/':
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
  }

  file {'/var/lib/puppet/':
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0751',
  }

  # Don't start puppet with network interface
  file { ['/etc/network/if-up.d/puppetd', '/etc/network/if-down.d/puppetd']:
    ensure => absent
  }

  $puppet_server = 'puppet'

  file{'/usr/local/sbin/launch-puppet':
    ensure  => present,
    mode    => '0755',
    content => template('puppet/launch-puppet.erb'),
    tag     => 'install-puppet',
  }

  # Run puppetd with cron instead of having it hanging around and eating so
  # much memory.
  cron { 'puppetd':
    ensure      => present,
    command     => '/usr/local/sbin/launch-puppet',
    user        => 'root',
    environment => 'MAILTO=root',
    minute      => 15,
    require     => File['/usr/local/sbin/launch-puppet'],
    tag         => 'install-puppet',
  }

  file { '/etc/cron.d/puppetd':
    ensure => absent
  }

  file { '/etc/default/puppet':
    source  => 'puppet:///modules/puppet/client/puppet.default',
    require => Package['puppet']
  }

#  file { '/etc/init.d/puppet':
#    source  => 'puppet:///modules/puppet/client/puppet.initd',
#    mode    => '0755',
#    require => Package['puppet']
#  }
}
