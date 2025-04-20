module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_cliente
  end

  private

  def authenticate_cliente
    authorization_header = request.headers['Authorization']
    return render json: { error: 'Token de acesso é obrigatório' }, status: :unauthorized unless authorization_header

    token_type, access_token = authorization_header.split(' ')
    return render json: { error: 'Formato de token inválido' }, status: :unauthorized unless token_type == 'Bearer' && access_token.present?

    return render json: { error: 'Token inválido ou expirado' }, status: :unauthorized unless CognitoAuth.valid_token?(access_token)

    @cliente = Cliente.authenticate(access_token)
    return render json: { error: 'Cliente não encontrado' }, status: :not_found unless @cliente
  end

  def current_cliente
    @cliente
  end
end
