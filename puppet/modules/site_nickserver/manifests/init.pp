#
# TODO: currently, this is dependent on some things that are set up in
# site_webapp
#
# (1) HAProxy -> couchdb
# (2) Apache
#
# It would be good in the future to make nickserver installable independently of
# site_webapp.
#

class site_nickserver {
  tag 'leap_service'
  Class['site_config::default'] -> Class['site_nickserver']

  include site_config::ruby::dev

  #
  # VARIABLES
  #

  $nickserver        = hiera('nickserver')
  $nickserver_domain = $nickserver['domain']
  $couchdb_user      = $nickserver['couchdb_nickserver_user']['username']
  $couchdb_password  = $nickserver['couchdb_nickserver_user']['password']

  # the port that public connects to (should be 6425)
  $nickserver_port   = $nickserver['port']
  # the port that nickserver is actually running on
  $nickserver_local_port = '64250'

  # couchdb is available on localhost via haproxy, which is bound to 4096.
  $couchdb_host      = 'localhost'
  # See site_webapp/templates/haproxy_couchdb.cfg.erg
  $couchdb_port      = '4096'

  $sources           = hiera('sources')

  # temporarily for now:
  $domain          = hiera('domain')
  $address_domain  = $domain['full_suffix']

  include site_config::x509::cert
  include site_config::x509::key
  include site_config::x509::ca

  #
  # USER AND GROUP
  #

  group { 'nickserver':
    ensure    => present,
    allowdupe => false;
  }

  user { 'nickserver':
    ensure    => present,
    allowdupe => false,
    gid       => 'nickserver',
    home      => '/srv/leap/nickserver',
    require   => Group['nickserver'];
  }

  vcsrepo { '/srv/leap/nickserver':
    ensure   => present,
    revision => $sources['nickserver']['revision'],
    provider => $sources['nickserver']['type'],
    source   => $sources['nickserver']['source'],
    owner    => 'nickserver',
    group    => 'nickserver',
    require  => [ User['nickserver'], Group['nickserver'] ],
    notify   => Exec['nickserver_bundler_update'];
  }

  exec { 'nickserver_bundler_update':
    cwd     => '/srv/leap/nickserver',
    command => '/bin/bash -c "/usr/bin/bundle check || /usr/bin/bundle install --path vendor/bundle"',
    unless  => '/usr/bin/bundle check',
    user    => 'nickserver',
    timeout => 600,
    require => [
      Class['bundler::install'], Vcsrepo['/srv/leap/nickserver'],
      Package['libssl-dev'], Class['site_config::ruby::dev'] ],

    notify  => Service['nickserver'];
  }

  #
  # NICKSERVER CONFIG
  #

  file { '/etc/nickserver.yml':
    content => template('site_nickserver/nickserver.yml.erb'),
    owner   => nickserver,
    group   => nickserver,
    mode    => '0600',
    notify  => Service['nickserver'];
  }

  #
  # NICKSERVER DAEMON
  #

  file {
    '/usr/bin/nickserver':
      ensure  => link,
      target  => '/srv/leap/nickserver/bin/nickserver',
      require => Vcsrepo['/srv/leap/nickserver'];

    '/etc/init.d/nickserver':
      owner   => root,
      group   => 0,
      mode    => '0755',
      source  => '/srv/leap/nickserver/dist/debian-init-script',
      require => Vcsrepo['/srv/leap/nickserver'];
  }

  # register initscript at systemd on nodes newer than wheezy
  # see https://leap.se/code/issues/7614
  case $::operatingsystemrelease {
    /^7.*/: { }
    default:  {
      exec { 'register_systemd_nickserver':
        refreshonly => true,
        command     => '/bin/systemctl enable nickserver',
        subscribe   => File['/etc/init.d/nickserver'],
        before      => Service['nickserver'];
      }
    }
  }

  service { 'nickserver':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      File['/etc/init.d/nickserver'],
      File['/usr/bin/nickserver'],
      Class['Site_config::X509::Key'],
      Class['Site_config::X509::Cert'],
      Class['Site_config::X509::Ca'] ];
  }

  #
  # FIREWALL
  # poke a hole in the firewall to allow nickserver requests
  #

  file { '/etc/shorewall/macro.nickserver':
    content => "PARAM   -       -       tcp    ${nickserver_port}",
    notify  => Service['shorewall'],
    require => Package['shorewall'];
  }

  shorewall::rule { 'net2fw-nickserver':
    source      => 'net',
    destination => '$FW',
    action      => 'nickserver(ACCEPT)',
    order       => 200;
  }

  #
  # APACHE REVERSE PROXY
  # nickserver doesn't speak TLS natively, let Apache handle that.
  #

  apache::module {
    'proxy': ensure => present;
    'proxy_http': ensure => present
  }

  apache::vhost::file {
    'nickserver':
      content => template('site_nickserver/nickserver-proxy.conf.erb')
  }

}
