# LimitedSessions
# (c) 2007-2017 t.e.morgan
# Made available under the MIT license

# This version is compatible with Rack 1.4-2.0 (possibly earlier; untested).
# Correspondingly, it is compatible with Rails 3.x-5.x.

module LimitedSessions
  # Rack middleware that should be installed *after* the session handling middleware
  class Expiry
    DEFAULT_OPTIONS = {
      recent_activity: nil,  # eg: 2.hours
      max_session: nil       # eg: 24.hours
    }

    def initialize(app, options={})
      @app = app
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def call(env)
      @env = env
      if @options[:recent_activity]
        if session[:last_visit] && (session[:last_visit] + @options[:recent_activity]) < Time.now.to_i
          logger.info "Session expired: no recent activity"
          clear_session
        end
        if @options[:recent_activity] > 600
          # Rounds to the nearest 5 minutes to minimize writes when a DB is in use
          session[:last_visit] = (Time.now.to_f/300).ceil*300
        else
          session[:last_visit] = (Time.now.to_f/10).ceil*10
        end
      end
      if @options[:max_session]
        session[:first_visit] ||= Time.now.to_i
        if (session[:first_visit] + @options[:max_session]) < Time.now.to_i
          logger.info "Session expired: max session length reached"
          clear_session
          session[:first_visit] ||= Time.now.to_i
        end
      end
      @app.call(env)
    end

    def session
      @env['rack.session'] || {}
    end
    def clear_session
      @env['rack.session'].clear
    end
    def logger
      (Rails.logger rescue nil) || @env['rack.logger']
    end
  end
end
