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
