#
# Sometimes when we upgrade the platform, we need to ensure that files that
# the platform previously created will get removed.
#
# These file removals don't need to be kept forever: we only need to remove
# files that are present in the prior platform release.
#
# We can assume that the every node is upgraded from the previous platform
# release.
#

class site_config::remove_files {

  #
  # Platform 0.7 removals
  #

  tidy {
    '/etc/rsyslog.d/99-tapicero.conf':;
    '/etc/rsyslog.d/99-leap-mx.conf':;
    '/etc/rsyslog.d/01-webapp.conf':;
    '/etc/rsyslog.d/50-stunnel.conf':;
    '/etc/logrotate.d/leap-mx':;
    '/etc/logrotate.d/stunnel':;
    '/var/log/stunnel4/stunnel.log':;
    'leap_mx':
      path => '/var/log/',
      recurse => true,
      matches => 'leap_mx*';
    '/srv/leap/webapp/public/provider.json':;
    '/srv/leap/couchdb/designs/tmp_users':
      recurse => true,
      rmdirs => true;
  }

}
