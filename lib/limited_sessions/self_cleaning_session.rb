# LimitedSessions
# (c) 2007-2017 t.e.morgan
# Made available under the MIT license

# This is the Rails 4-5.x version.

module LimitedSessions
  class SelfCleaningSession < ActiveRecord::SessionStore::Session

    # disable short circuit by Dirty module; ensures :updated_at is kept updated
    self.partial_writes = false

    self.table_name = 'sessions'

    cattr_accessor :recent_activity, :max_session, :self_clean_sessions
    self.recent_activity      = 2.hours # eg: 2.hours ; nil disables
    self.max_session          = nil     # eg: 24.hours ; nil disables
    self.self_clean_sessions  = 1000    # 0 disables

    scope :active_session, lambda {
      where("updated_at > ?", Time.current - recent_activity) if recent_activity
    }
    scope :current_session, lambda {
      where("created_at > ?", Time.current - max_session) if max_session
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
        return if defined?(@@last_check) && @@last_check == Time.now.to_i
        if rand(self_clean_sessions) == 0
          @@last_check = Time.now.to_i
          # logger.info "SelfCleaningSession :: scrubbing expired sessions"
          look_back_recent = recent_activity || 1.week
          if max_session
            self.where('updated_at < ? OR created_at < ?', Time.current - look_back_recent, Time.current - max_session).delete_all
          elsif columns_hash['updated_at']
            self.where('updated_at < ?', Time.current - look_back_recent).delete_all
          else
            # logger.warning "WARNING: Unable to self-clean Sessions table; updated_at column is missing"
            self.self_clean_sessions = 0
          end
        end
      end
    end

  end
end
