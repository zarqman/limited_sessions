# LimitedSessions
# (c) 2007-2010 t.e.morgan
# made available under the MIT license
#
# this is the rails 2.3 version; it is /not/ compatible with earlier versions. 

require 'ipaddr'

module ActiveRecord
  class SessionStore < ActionController::Session::AbstractStore
    class Session < ActiveRecord::Base
      self.partial_updates = false if respond_to? :partial_updates=
      
      cattr_accessor :recent_activity_limit, :hard_session_limit, :auto_clean_sessions
      self.recent_activity_limit = 2.hours  # required
      self.hard_session_limit = nil         # eg: 24.hours
      self.auto_clean_sessions = 1000       # 0 disables
      
      class << self
        alias :find_by_session_id_old_version :find_by_session_id
        def find_by_session_id(session_id)
          consider_auto_clean
          
          now = if self.default_timezone == :utc
                  Time.now.utc
                else
                  Time.now
                end
          
          if @@hard_session_limit
            find(:first, :conditions => ['session_id = ? AND updated_at > ? AND created_at > ?', session_id, now - @@recent_activity_limit, now - @@hard_session_limit])
          else
            find(:first, :conditions => ['session_id = ? AND updated_at > ?', session_id, now - @@recent_activity_limit])
          end
        end
        
        private
        def consider_auto_clean
          return if @@auto_clean_sessions == 0
          if rand(@@auto_clean_sessions) == 0
            
            now = if self.default_timezone == :utc
                    Time.now.utc
                  else
                    Time.now
                  end
            
            if @@hard_session_limit
              delete_all ['updated_at < ? OR created_at < ?', now - @@recent_activity_limit, now - @@hard_session_limit]
            else
              delete_all ['updated_at < ?', now - @@recent_activity_limit]
            end
          end
        end
        
      end
    end

  end
end


module ActionController
  class Request < Rack::Request
    cattr_accessor :ip_restriction
    self.ip_restriction = :none           # options-  :none, :exact, :subnet
    cattr_accessor :ipv4_mask, :ipv6_mask
    self.ipv4_mask = 24
    self.ipv6_mask = 64
    cattr_accessor :recent_activity_limit, :hard_session_limit
    self.recent_activity_limit = nil      # eg: 2.hours
    self.hard_session_limit = nil         # eg: 24.hours
    
    alias :session_old_version :session
    def session
      # using  @env['rack.session'] = {}  instead of  reset_session  as the latter
      # also resets the session id and that seems to cause some really strange
      # behavior
      if session_old_version[:ip]
        case @@ip_restriction
        when :exact
          unless session_old_version[:ip] == remote_ip
            ActionController::Base.logger.error "Session violation: IP #{session_old_version[:ip]} expected; #{remote_ip} received"
            @env['rack.session'] = {}
          end
        when :subnet
          session_ip = IPAddr.new(session_old_version[:ip])
          the_mask = session_ip.ipv4? ? @@ipv4_mask : @@ipv6_mask
          session_ip.send(:mask!, the_mask)
          current_ip = IPAddr.new(remote_ip)
          unless session_ip.include?(current_ip)
            ActionController::Base.logger.error "Session violation: IP #{session_ip}/#{the_mask} expected; #{remote_ip} received"
            @env['rack.session'] = {}
          end
        end
      end
      
      if @@recent_activity_limit
        if session_old_version[:last_visit]
          if (session_old_version[:last_visit] + @@recent_activity_limit) < Time.now.to_i
            ActionController::Base.logger.info "Session expired: no recent activity"
            @env['rack.session'] = {} 
          end
        end
        # Rounds to the nearest 5 minutes to minimize writes when a DB is in use
        session_old_version[:last_visit] = (Time.now.to_f/300).ceil*300
      end
      if @@hard_session_limit
        session_old_version[:first_visit] ||= Time.now.to_i
        if (session_old_version[:first_visit] + @@hard_session_limit) < Time.now.to_i
          ActionController::Base.logger.info "Session expired: hard limit reached"
          @env['rack.session'] = {}
        end
      end
      
      session_old_version[:ip] ||= remote_ip
      session_old_version
    end

    
    alias :reset_session_old_version :reset_session
    def reset_session
      old_id = session_options[:id]
      
      klass = ActionController::Base.session_store
      if old_id && !klass.is_a?(ActionController::Session::CookieStore)
        # DB-backed sessions need to be wiped to protected against session_id replay attacks
        ss = klass.new(:no_app, ActionController::Base.session_options)
        ss.send :set_session, @env, old_id, {}
      end
      reset_session_old_version
    end
    
  end
end