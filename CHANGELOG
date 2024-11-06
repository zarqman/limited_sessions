* 2024-nov-06 - v5.0.3

  - Support Rails 7.2

* 2023-oct-07 - v5.0.2

  - Support Rails 7.1 & Rack 3

* 2022-aug-10 - v5.0.1

  - Fix for deprecation warning in Rails 7

* 2021-apr-20 - v5.0.0

  - Drop support for Rack <= 2.0.8 and Rails < 5.2
  - Update for new rubies
  - Cleanup readme and comments

* 2017-may-22 - v4.2.0

  - Fixed ActiveRecord session cleanup on Rails 5.1
  - Prevent ActiveRecord session cleanup from possibly running more often than
    configured due to Rails loading sessions more than once per request.

* 2016-feb-12 - v4.1.0

  - Support Rails 5.0 & Rack 2.0

* 2013-dec-14 - v4.0.1

  - Fix deprecation warning

* 2013-jun-15 - Support for Rails 4

  - v4.0.0 - Rails 4 compatibility. Use v3.x.x for Rails 3 apps.
  - For non-ActiveRecord session stores, no change is required from the
    previous version.
  - For ActiveRecord session stores, you must add the
    'activerecord-session_store' gem to your Gemfile and it must be
    above limited_sessions so that it will be auto-detected properly.
    This is the only change required.

* 2012-nov-14 - Merge changes from ejdraper

  - Lower Rack requirement to v1.2.5+ for Rails 3.0 compatibility
  - Fix an issue with scope chaining

* 2012-jun-25 - Rails 3 and generic Rack compatibility; much simplified

  - LimitedSessions has been broken up into two parts:
    - Rack-compatible middleware that handles session time limits. This
      *should* work for all session stores. Just requires Rack, not
      necessarily Rails.
    - Rails 3 specific enhancement to the ActiveRecord Session Store
      that also cleans up stale session records.
  - Rails 3.2 (maybe 3.0 and 3.1; untested) compatibility. No longer
    compatible with Rails 2--use previous versions.
  - All IP matching and restrictions have been removed. In short, dual-
    stack environments (IPv4+IPv6) have a tendency to bounce between v4
    and v6 at times. This causes sessions to be aborted regularly.

* 2010-jul-20 - IPv6, replay attack mitigation, more non-AR support

  - IPv6 now works for subnet matching.
  - New options to configure the allowed subnet size (both IPv4 and
    IPv6) added.
  - Plugin now enhances reset_session to clear old session data from
    the DB; this prevents session_id replay attacks when using
    DB-backed session storage.
  - Session activity and hard limits now work with non-ActiveRecord
    session stores. Configuration is done differently depending on
    which session store is in use.

* 2009-apr-22 - update to support rails 2.3

  - Rails 2.3 changed the internal session code substantially. This new
    version now supports rails 2.3. Note that is no longer supports any
    version of rails prior to 2.3 -- see the README for where to find
    an older version of this plugin for rails 2.2 and earlier.
  - CONFIGURATION OPTIONS HAVE CHANGED. This is required by the new
    support for rails 2.3. See the README for more information.

* 2008-jul-23 - update to improve rails 2.1 compatibility

  - disable partial-updates for the session table
    (thanks to eilonon erkki for bringing the problem to my attention)

* 2007-sep-06 - initial release
