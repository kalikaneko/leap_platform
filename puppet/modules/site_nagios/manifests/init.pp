# setup nagios on monitoring node
class site_nagios  {
  tag 'leap_service'

  include site_config::default

  Class['site_config::default'] -> Class['site_nagios']

  include site_nagios::server

  # remove leftovers on monitoring nodes
  include site_config::remove::monitoring
}
