class puppet::common {
  include apt::backports
  apt::preferences { puppet-common:
    package => puppet-common, 
    pin => "release a=lenny-backports",
    priority => 999,
    require => Apt::Sources_List["lenny-backports"]
  }
}
