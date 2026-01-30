class UsersController < ApplicationController
  def create
    if params[:register]
      existing_user = User.find_by(email: params[:email])
      if existing_user
        begin
          # Tenta verificar se o hash de senha atual é válido (BCrypt)
          BCrypt::Password.new(existing_user.password_digest)
          # Se for válido, o usuário já está no novo formato.
          render json: { error: "E-mail já cadastrado!" }, status: :conflict
        rescue BCrypt::Errors::InvalidHash
          # Conta antiga detectada (senha em texto puro). Permitimos a re-inscrição para converter.
          existing_user.password = params[:password]
          if existing_user.save
            token = JsonWebToken.encode(user_id: existing_user.id)
            render json: { user: existing_user.as_json(except: :password_digest), token: token }, status: :ok
          else
            render json: { error: existing_user.errors.full_messages.join(', ') }, status: :unprocessable_entity
          end
        end
      else
        # Fluxo normal de registro
        user = User.new(email: params[:email], password: params[:password])
        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: { user: user.as_json(except: :password_digest), token: token }, status: :created
        else
          render json: { error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end
    else
      user = User.find_by(email: params[:email])
      begin
        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { user: user.as_json(except: :password_digest), token: token }, status: :ok
        else
          render json: { error: "Email ou senha inválidos" }, status: :unauthorized
        end
      rescue BCrypt::Errors::InvalidHash
        # Conta antiga detectada (senha em texto puro)
        if user && user.password_digest == params[:password]
          # Senha coincide com o texto puro! Vamos converter agora.
          user.password = params[:password]
          if user.save
            token = JsonWebToken.encode(user_id: user.id)
            render json: { user: user.as_json(except: :password_digest), token: token }, status: :ok
          else
            render json: { error: "Erro ao atualizar conta: #{user.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
          end
        else
          render json: { error: "Email ou senha inválidos" }, status: :unauthorized
        end
      end
    end
  end

  before_action :authorize_request, only: [:show]

  def show
    user = User.find(params[:id])
    render json: user.as_json(except: :password_digest)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Usuário não encontrado" }, status: :not_found
  end
end