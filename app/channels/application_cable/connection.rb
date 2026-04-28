module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        if user_id = request.session[:user_id]
          self.current_user = User.find_by(id: user_id)
        end
      end
  end
end
