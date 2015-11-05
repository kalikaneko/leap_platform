# install mod_mpm_event (needed for jessie hosts)
class site_apache::module::mpm_event ( $ensure = present )
{

  apache::module { 'mpm_event': ensure => $ensure }

}
