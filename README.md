# LimitedSessions

LimitedSessions provides two distinct features, each in a separate part:

* Rack-compatible middleware that expires sessions based on inactivity or maximum session length. The middleware supports any session storage type, including cookies, Redis, ActiveRecord, etc.

* Rails extension to the (now separate) ActiveRecord Session Store to auto-cleanup stale session records.


## Features

* For all session stores:
  * Configurable session expiry time (eg: 2 hours from last page access)
  * Optional hard maximum limit from beginning of session (eg: 24 hours)

* When using the ActiveRecord Session Store:
  * DB-based handling of session expiry (activity and hard limits) instead of by session paramters
  * Auto-cleaning of expired session records


## Requirements

* Rack and any Rack-compatible app (including Rails)
* Utilizing Rack's (or Rails') sessions
* For ActiveRecord session enhancements:
  * Must be using the standard ActiveRecord::SessionStore
    (`ActionDispatch::Session::ActiveRecordStore.session_store = :active_record_store`)
  * Ensure your sessions table has an `updated_at` column
  * If using hard session limits, a `created_at` column is needed too


## Compatibility

The middleware should be compatible with any framework using a recent version of Rack. It has been tested with Rack 2.x and Rails 5.2-7.0.

The optional ActiveRecord Session Store extension requires Rails.

If using Rack < 2.0.9 or Rails < 5.2, use LimitedSessions 4.x.


## Upgrading

No changes are required to upgrade from LimitedSessions 4.x to 5.0.

Upgrading `activerecord-session_store` from 1.x to 2.x may require changes. See its own upgrade instructions.


## Installation

Add this gem to your Gemfile or otherwise make it available to your app. Then, configure as required.

```ruby
gem 'limited_sessions', '~> 5'
```

If storing sessions in the DB using ActiveRecord with AR Session Store:

```ruby
gem 'activerecord-session_store'
gem 'limited_sessions', '~> 5'
```

`activerecord-session_store` must be loaded first in order for `limited_sessions` to properly detect it.


## Configuration

### Rack Middleware with Rails

1. Add/update `config/initializers/session_store.rb` and append the following:

    ```ruby
    config.middleware.insert_after ActionDispatch::Flash, LimitedSessions::Expiry, \
      recent_activity: 2.hours, max_session: 24.hours
    ```

2. Configuration options.

    The example above shows both configuration options. You may include one, both, or none.

    #### Session activity timeout
    Example: `recent_activity: 2.hours`
    By default, the session activity timeout is disabled (`nil`).

    #### Maximum session length
    Example: `max_session: 24.hours`
    By default, the maximum session length is disabled (`nil`).


### Rack Middleware apart from Rails

1. In `config.ru`, add the following *after* the middleware that handles your sessions.

    ```ruby
    use LimitedSessions::Expiry, recent_activity: 2.hours, max_session: 24.hours
    ```

2. For configuration options, see #2 above, under Rack Middleware with Rails.


### ActionRecord Session Store extension

1. If you don't already have an `updated_at` column on your sessions table, create a migration and add it. If you plan to use the hard session limit feature, you'll also need to add `created_at`.

2. Tell Rails to use your the new session store. Change `config/initializers/session_store.rb` to reflect the following:

    ```ruby
    Rails.application.config.session_store :active_record_store
    ActionDispatch::Session::ActiveRecordStore.session_class = LimitedSessions::SelfCleaningSession
    ```

3. Configuration options.

    Each of the following options should also be added to your initializer file from step 2.

    #### Self-cleaning
    By default, SelfCleaningSession will clean the sessions table every 1000 page views. Technically, it's a 1 in 1000 chance on each page. For most sites this is good. Higher traffic sites may want to increase it to 10000 or more. Set to 0 to disable self-cleaning.

    ```ruby
    LimitedSessions::SelfCleaningSession.self_clean_sessions = 1000
    ```

    #### Session activity timeout
    The default session activity timeout is 2 hours. This uses the `updated_at` column which will be updated on every page load.

    This can also be disabled by setting to `nil`. However, the `updated_at` column is still required for self-cleaning and will effectively function as if set to `1.week`. If you really want it longer, set it to `1.year` or something.

    ```ruby
    LimitedSessions::SelfCleaningSession.recent_activity = 2.hours
    ```

    #### Maximum session length
    By default, maximum session length handling is disabled. When enabled, it uses the `created_at` column to do its work.

    A value of `nil` disables this feature and `created_at` does not need to exist in this case.

    ```ruby
    LimitedSessions::SelfCleaningSession.max_session = 12.hours
    ```


## Questions

* Do I need both the middleware and the ActiveRecord Session Store?

  No. While it should work, it is not necessary to use both the middleware
  and the ActiveRecord Session Store. If you are storing sessions via AR,
  then use the ActiveRecord Session Store. If you are storing sessions any
  other way, then use the middleware.

* I'm storing sessions in {Memcache, Redis, etc.} and they auto-expire sessions. Do I need this?

  Maybe, maybe not. Normally, that auto-expire period is equivalent to LimitedSessions' :recent_activity. If that's all you want, then you don't need this. However, if you'd also like to put a maximum cap on session length, regardless of activity, then LimitedSessions' `:max_session` feature will still be useful.

* Can I use the middleware with ActiveRecord instead of the ActionRecord Session Store enhancement?

  Yes. Session expiry (recent activity and max session length) should work fine in this circumstance. The only thing you won't get is self-cleaning of the AR sessions table.

* How are session expiry times tracked?

  The middleware adds one or two keys to the session data: `:last_visit` and/or `:first_visit`.

  The AR enhancement uses `updated_at` and possibly `created_at`.

* How is this different from using the session cookie's own expires= value?

  The cookie's own value puts the trust in the client to self-expire. If you really want to control session lengths, then you need to manage the values on the application side. LimitedSessions is fully compatible with the cookie's expires= value, however, and the two can be used together.

* What's the difference between `:recent_activity` and `:max_session`?

  Recent activity requires regular access on your site. If it's set to 15 minutes, then a page must be loaded at least once every 15 minutes.

  Max session is a cap on the session from the very beginning. If it's set to 12 hours, then even if a user is accessing the page constantly, and not triggering the recent activity timeout, after 12 hours their session would be reset anyway.

* What are the security implications of using LimitedSessions?

  LimitedSessions enhances security by reducing risk of session cookie replay attacks. The specifics will depend on what cookie store you're using.

  For Rails' default cookie store, `:max_session` handling is perhaps most valuable as it guarantees an end to the session. Rails' default behavior allows a session to last for an infinite time. If a cookie is somehow exposed, the holder of the cookie has an open-ended session. Note that signing and/or encryption do not mitigate this.

  For any session store that uses a server-side database (AR, memcache, Redis, etc.), at least the user can formally logout and terminate the session. Auto-expiring sessions (memcache, Redis, AR w/SelfCleaningSession, etc.) will also expire if allowed to, but can also be maintained perpetually by ongoing access.

  Since the cookie store doesn't expire ever, `:recent_activity` addresses this by making sessions expire similarly to if memcache, Redis, or something similar was being used.

  It is recommended to use both aspects of LimitedSessions for best security.

* What are the performance implications of using LimitedSessions?

  The middleware should have minimal impact.

  The AR enhancement should result in an overall net gain in performance as the size of the AR sessions table will be kept to a smaller size. The 1 in 1000 hit (or whatever you've configured it to) may be slightly slower while the database cleanup is in progress.


## Contributing

1. Fork it ( https://github.com/zarqman/limited_sessions/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

MIT
