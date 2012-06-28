# LimitedSessions
# (c) 2007-2012 t.e.morgan
# Made available under the MIT license

# This is the Rails 3.x version; it is /not/ compatible with Rails 2.x.

module LimitedSessions
  class SelfCleaningSession < ActiveRecord::SessionStore::Session

    # disable short circuit by Dirty module; ensures :updated_at is kept updated
    self.partial_updates = false

    self.table_name = 'sessions'

    cattr_accessor :recent_activity, :max_session, :self_clean_sessions
    self.recent_activity      = 2.hours # eg: 2.hours ; nil disables
    self.max_session          = nil     # eg: 24.hours ; nil disables
    self.self_clean_sessions  = 1000    # 0 disables

    scope :active_session, lambda {
      recent_activity ? where("updated_at > ?", Time.current - recent_activity) : []
    }
    scope :current_session, lambda {
      max_session ? where("created_at > ?", Time.current - max_session) : []
    }

    class << self
      # This disables compatibility with 'sessid'. The key column *must* be session_id.
      # If this is a problem, use a migration and rename the column.
      def find_by_session_id(session_id)
        consider_self_clean
        active_session.current_session.where(:session_id=>session_id).first
      end

      private
      def consider_self_clean
        return if self_clean_sessions == 0
        if rand(self_clean_sessions) == 0
          # logger.info "SelfCleaningSession :: scrubbing expired sessions"
          look_back_recent = recent_activity || 1.week
          if max_session
            delete_all ['updated_at < ? OR created_at < ?', Time.current - look_back_recent, Time.current - max_session]
          elsif columns_hash['updated_at']
            delete_all ['updated_at < ?', Time.current - look_back_recent]
          else
            # logger.warning "WARNING: Unable to self-clean Sessions table; updated_at column is missing"
            self.self_clean_sessions = 0
          end
        end
      end
    end

  end
end
