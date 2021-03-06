class puppet::master inherits puppet::client {
    package { puppetmaster: 
      ensure    => $facter_version ? {
        ""      => latest,
        default => $facter_version,
      }
    }

    if $debian::lenny {
      apt::preferences { puppetmaster:
        package  => puppetmaster, 
        pin      => "release a=lenny-backports",
        priority => 999,
        before   => Package[puppetmaster],
        require  => Apt::Sources_List["lenny-backports"]
      }
    }

    if $debian::squeeze {
      apt::preferences { puppetmaster:
        package  => puppetmaster, 
        pin      => "release a=squeeze-backports",
        priority => 999,
        before   => Package[puppetmaster],
        require  => Apt::Sources_List["squeeze-backports"]
      }
    }

    service { puppetmaster:
      ensure  => running,
      enable  => true,
      pattern => "/usr/bin/puppet master",
      require => [ Package[puppet], Package[puppetmaster] ]
    }

    Service[puppet]{
        require +> Service[puppetmaster],
    }

    File["/etc/puppet/puppet.conf"]{
        source => [ "puppet://$server/files/puppet/master/puppet.conf",
                    "puppet://$server/modules/puppet/master/puppet.conf" ],
        notify => [Service[puppet],Service[puppetmaster] ],
    }

    file { "/var/lib/puppet/reports": 
      owner  => puppet,
      ensure => directory
    }

    file { "/etc/puppet/fileserver.conf":
        source => [ "puppet://$server/files/puppet/master/fileserver.conf",
                    "puppet://$server/modules/puppet/master/fileserver.conf" ],
        notify => [Service[puppet],Service[puppetmaster] ],
        owner  => root, group => 0, mode => '0644';
    }

    if $puppetmaster_storeconfigs {
        include puppet::master::storeconfigs
    }

    # restart the master from time to time to avoid memory problems
    file{'/etc/cron.d/puppetmaster.cron':
        source => "puppet://$server/modules/puppet/puppetmaster.cron",
        owner  => root, group => 0, mode => '0644';
    }

    # namespaceauth.conf breaks puppetmaster
    File["/etc/puppet/namespaceauth.conf"] { ensure => absent }

    # used to create passwords
    package { pwgen: }

    file { ["/var/lib/puppet/conf", "/var/lib/puppet/conf/releases", "/var/lib/puppet/conf/shared"]:
      ensure  => directory,
      mode    => '2775',
      group   => src,
      require => File["/var/lib/puppet"]
    }

    file { "/var/lib/puppet/conf/current":
      mode  => '0775',
      group => src
    }
    include puppet::master::logrotate
}


