class MessagesController < ApplicationController
  before_action :authorize_request
  def index
    u1, u2 = params[:user_id], params[:recipient_id]
    @messages = Message.where("(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)", u1, u2, u2, u1).order(:created_at)
    render json: @messages
  end

  def create
    @message = Message.new(message_params)
    if @message.save
      # Aqui o broadcast corrigido para não dar erro de argumentos
      ActionCable.server.broadcast("chat_channel", { message: @message })
      render json: @message
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end # fecha o create

  private

  def message_params
    params.require(:message).permit(:content, :sender_id, :recipient_id)
  end
end # fecha a classe MessagesController