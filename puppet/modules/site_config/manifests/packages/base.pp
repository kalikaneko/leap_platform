# install default packages and remove unwanted packages
class site_config::packages::base {


  # base set of packages that we want to have installed everywhere
  package { [ 'etckeeper', 'screen', 'less', 'ntp' ]:
    ensure => installed,
  }

  # base set of packages that we want to remove everywhere
  package { [ 'acpi', 'eject', 'ftp', 'laptop-detect', 'lpr',
              'portmap', 'pppconfig', 'pppoe', 'pump', 'qstat',
              'samba-common', 'samba-common-bin', 'smbclient', 'tcl8.5',
              'tk8.5', 'os-prober', 'unzip', 'xauth', 'x11-common',
              'x11-utils', 'xterm' ]:
    ensure => absent;
  }

  notice($::site_config::params::environment)
  if $::site_config::params::environment != 'local' {
    package { [ 'nfs-common', 'nfs-kernel-server', 'rpcbind' ]:
      ensure => purged;
    }
  }
}
