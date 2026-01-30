module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      begin
        decoded = JsonWebToken.decode(token)
        if (user = User.find(decoded[:user_id]))
          user
        else
          reject_unauthorized_connection
        end
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        reject_unauthorized_connection
      end
    end
  end
end
