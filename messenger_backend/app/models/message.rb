class Message < ApplicationRecord
  # Esta linha avisa o WebSocket toda vez que uma mensagem nova for salva
  after_create_commit { ActionCable.server.broadcast("chat_channel", self) }
end