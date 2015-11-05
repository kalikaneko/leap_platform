# install basic apache modules needed for all services (nagios, webapp)
class site_apache::common {

  include site_apache::module::rewrite
  include site_apache::module::env

  class { '::apache': no_default_site => true, ssl => true }

  # the ssl mod config depends on these modules to be installed
  # on debian jessie
  if ( versioncmp($::apache_version, '2.4') >= 0 ) {
      apache::module {
        'mime':;
        'socache_shmcb':;
      }
  }

  if ( versioncmp($::apache_version, '2.4') >= 0 ) {
      apache::module { 'mpm_event':;
      }
  }


  include site_apache::common::tls
}
