module LimitedSessions
end

require 'limited_sessions/expiry'
if defined? ActiveRecord::SessionStore::Session
  require 'limited_sessions/self_cleaning_session'
end
