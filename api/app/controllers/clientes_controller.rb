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
    cpf = params[:cpf]
    password = params[:password]
  
    cliente = Cliente.find_by(cpf: cpf)
  
    unless cliente
      return render json: { error: 'Cliente não encontrado no sistema pelo CPF informado' }, status: :not_found
    end
  
    tokens = CognitoAuth.authenticate(cliente.email, password)
  
    unless tokens
      return render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  
    render json: { 
      cliente: cliente, 
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
    params.require(:cliente).permit(:nome, :data_nascimento, :cpf, :email)
  end
end
