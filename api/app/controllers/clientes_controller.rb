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
    cliente = Cliente.new(cliente_params)
    if cliente.save
      render json: cliente, status: :created
    else
      render json: { errors: cliente.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @cliente.update(cliente_params)
      render json: @cliente, status: :ok
    else
      render json: { errors: @cliente.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    email = params[:email]
    password = params[:password]

    token = CognitoAuth.authenticate(email, password)

    if token
      cliente = Cliente.find_by(email: email)
      if cliente
        render json: { cliente: cliente, token: token }, status: :ok
      else
        render json: { error: 'Usuário não encontrado no sistema' }, status: :not_found
      end
    else
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  end

  private

  def set_cliente
    @cliente = Cliente.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Cliente não encontrado' }, status: :not_found
  end

  def cliente_params
    params.require(:cliente).permit(:nome, :data_nascimento, :cpf, :email)
  end
end
