# install mod_alias
class site_apache::module::alias ( $ensure = present )
{

  apache::module { 'alias': ensure => $ensure }

  # from 2.4, /etc/apache2/mods-enabled/alias.conf contains the "Require"
  # directive which needs "authz_core" mod enabled

  if ( versioncmp($::apache_version, '2.4') >= 0 ) {
    apache::module { 'authz_core': ensure => $ensure }
  }

}
