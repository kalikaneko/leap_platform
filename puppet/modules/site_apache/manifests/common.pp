# install basic apache modules needed for all services (nagios, webapp)
class site_apache::common {

  include site_apache::module::rewrite
  include site_apache::module::env

  class { '::apache': no_default_site => true, ssl => true }

  # needed for the mod_ssl config
  apache::module { 'mime':; }

  # load mods depending on apache version
  if ( versioncmp($::apache_version, '2.4') >= 0 ) {
    # apache >= 2.4, debian jessie
    apache::module {
      # needed for mod_ssl config
      'socache_shmcb':;
      # generally needed
      'mpm_prefork':;
    }
  } else {
    # apache < 2.4, debian wheezy
    apache::module {
      # for "Order" directive, i.e. main apache2.conf
      'authz_host':;
    }
  }

  include site_apache::common::tls
}
