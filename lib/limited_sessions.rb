# LimitedSessions
# (c) 2007-2009 t.e.morgan
# made available under the MIT license
#
# this is the rails 2.3 version; it is /not/ compatible with earlier versions. 

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
    
    alias :session_old_version :session
    def session
      # using  @env['rack.session'] = {}  instead of  reset_session  as the latter
      # also resets the session id and that seems to cause some really strange
      # behavior
      case @@ip_restriction
      when :exact
        @env['rack.session'] = {} unless session_old_version['ip'] == remote_ip
      when :subnet
        session_ip = /^\d+\.\d+\.\d+\./.match(session_old_version['ip']) || ["1"]
        current_ip = /^\d+\.\d+\.\d+\./.match(remote_ip) || ["2"]
        @env['rack.session'] = {} unless session_ip[0] == current_ip[0]
      end
      session_old_version['ip'] = remote_ip unless session_old_version['ip']
      session_old_version
    end
    
  end
end