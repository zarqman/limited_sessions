# LimitedSessions
# (c) 2007-2012 t.e.morgan
# Made available under the MIT license

module LimitedSessions
end

require 'limited_sessions/expiry'
if defined? ActiveRecord
  require 'limited_sessions/self_cleaning_session'
end
