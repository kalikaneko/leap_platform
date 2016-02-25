class site_static {
  tag 'leap_service'

  include site_config::default
  include site_config::x509::cert
  include site_config::x509::key
  include site_config::x509::ca_bundle

  $static        = hiera('static')
  $domains       = $static['domains']
  $formats       = $static['formats']
  $bootstrap     = $static['bootstrap_files']
  $tor           = hiera('tor', false)

  if $bootstrap['enabled'] {
    $bootstrap_domain  = $bootstrap['domain']
    $bootstrap_client  = $bootstrap['client_version']
    file { '/srv/leap/provider.json':
      content => $bootstrap['provider_json'],
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0444';
    }
    # It is important to always touch provider.json: the client needs to check x-min-client-version header,
    # but this is only sent when the file has been modified (otherwise 304 is sent by apache). The problem
    # is that changing min client version won't alter the content of provider.json, so we must touch it.
    exec { '/bin/touch /srv/leap/provider.json':
      require => File['/srv/leap/provider.json'];
    }
  }

  include apache::module::headers
  include apache::module::alias
  include apache::module::expires
  include apache::module::removeip
  include apache::module::dir
  include apache::module::negotiation
  include site_apache::common
  include site_config::ruby::dev

  if (member($formats, 'rack')) {
    include site_apt::preferences::passenger
    class { 'passenger':
      use_munin => false,
      require   => Class['site_apt::preferences::passenger']
    }
  }

  if (member($formats, 'amber')) {
    rubygems::gem{'amber-0.3.8':
       require =>  Package['zlib1g-dev']
     }

    package { 'zlib1g-dev':
        ensure => installed
    }
  }

  create_resources(site_static::domain, $domains)

  if $tor {
    $hidden_service = $tor['hidden_service']
    if $hidden_service['active'] {
      include site_webapp::hidden_service
    }
  }

  include site_shorewall::defaults
  include site_shorewall::service::http
  include site_shorewall::service::https
}
