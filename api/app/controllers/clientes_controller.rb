class ClientesController < ApplicationController
  before_action :set_cliente, only: %i[show update]

  def index
    clientes = Cliente.all
    render json: clientes, status: :ok
  end

  def show
    render json: @cliente, status: :ok
  end

  def create
    data = cliente_params.to_h
    password = data.delete("password")

    cognito_response = CognitoAuth.register(data["email"], password)
    if cognito_response.is_a?(Hash) && cognito_response[:error].present?
      return render json: { error: "Erro ao cadastrar usuário no Cognito: #{cognito_response[:error]}" },
                    status: :unprocessable_entity
    end

    cliente = Cliente.new(data)
    if cliente.save
      render json: cliente, status: :created
    else
      CognitoAuth.delete_user(data["email"])
      render json: { errors: cliente.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    new_email    = cliente_params[:email]
    new_password = cliente_params[:password]

    if new_email.present? || new_password.present?
      cognito_response = CognitoAuth.update_user(@cliente.email, new_email: new_email, new_password: new_password)
      if cognito_response.is_a?(Hash) && cognito_response[:error].present?
        return render json: { error: "Erro ao atualizar usuário no Cognito: #{cognito_response[:error]}" },
                      status: :unprocessable_entity
      end
    end

    local_params = cliente_params.except(:password)

    if @cliente.update(local_params)
      render json: @cliente, status: :ok
    else
      render json: { errors: @cliente.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    email = params[:email]
    password = params[:password]
  
    cliente = Cliente.find_by(email: email)
  
    unless cliente
      return render json: { error: 'Cliente não encontrado no sistema pelo email informado' }, status: :not_found
    end
  
    tokens = CognitoAuth.authenticate(cliente.email, password)
  
    unless tokens
      return render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  
    render json: {  
      token: tokens[:id_token], 
      access_token: tokens[:access_token], 
      refresh_token: tokens[:refresh_token] 
    }, status: :ok
  end  

  private

  def set_cliente
    @cliente = Cliente.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Cliente não encontrado' }, status: :not_found
  end

  def cliente_params
    params.require(:cliente).permit(:nome, :email, :password)
  end
end
