require 'aws-sdk-cognitoidentityprovider'

class CognitoAuth
  def self.register(email, password, cpf)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    client.sign_up(
      client_id: ENV['COGNITO_USER_POOL_CLIENT_ID'],
      username: cpf, # Utilizando o CPF como identificador principal
      password: password,
      user_attributes: [
        { name: 'email', value: email },
        { name: 'custom:cpf', value: cpf }  # Corrigido: prefixo "custom:" adicionado
      ]
    )
    true
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    { error: e.message }
  end

  def self.authenticate(email, password)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    begin
      resp = client.initiate_auth(
        client_id: ENV['COGNITO_USER_POOL_CLIENT_ID'],
        auth_flow: 'USER_PASSWORD_AUTH',
        auth_parameters: {
          'USERNAME' => email,
          'PASSWORD' => password
        }
      )
      return nil unless resp.authentication_result

      {
        id_token: resp.authentication_result.id_token,
        access_token: resp.authentication_result.access_token,
        refresh_token: resp.authentication_result.refresh_token
      }
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
           Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      nil
    end
  end

  def self.delete_user(email)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    client.admin_delete_user(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: email
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error "Erro ao deletar usuário no Cognito: #{e.message}"
  end
end
