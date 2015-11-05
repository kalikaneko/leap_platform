# install mod_env, needed by api.conf
class site_apache::module::env ( $ensure = present )
{

  apache::module { 'env': ensure => $ensure }

}
