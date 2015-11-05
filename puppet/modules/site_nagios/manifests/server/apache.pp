# set up apache for nagios
class site_nagios::server::apache {
  include x509::variables
  include site_config::x509::commercial::cert
  include site_config::x509::commercial::key
  include site_config::x509::commercial::ca

  apache::module {
    'authn_file':;
    # "AuthUserFile"
    'authz_user':;
    # "AuthType Basic"
    'auth_basic':;
    # for "DirectoryIndex"
    'dir':;
    'php5':;
    'cgi':;
  }

  # apache >= 2.4, debian jessie
  if ( versioncmp($::apache_version, '2.4') >= 0 ) {
    apache::module { 'authn_core':; }
  }

}
