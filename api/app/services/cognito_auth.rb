require 'aws-sdk-cognitoidentityprovider'

class CognitoAuth
  def self.register(email, password, cpf)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    # Cria o usuário de forma administrativa, sem envio de e-mail de confirmação
    client.admin_create_user(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: cpf,  # Usa o CPF como identificador principal
      user_attributes: [
        { name: 'email', value: email },
        { name: 'email_verified', value: 'true' }, # Marca o e-mail como verificado
        { name: 'custom:cpf', value: cpf }
      ],
      message_action: 'SUPPRESS'  # Não envia o e-mail de verificação
    )
    # Define a senha como permanente, confirmando-a imediatamente
    client.admin_set_user_password(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: cpf,
      password: password,
      permanent: true
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
          'USERNAME' => email,  # Apesar de o username ser o CPF, o pool permite login via alias (email)
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

  def self.delete_user(cpf)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    client.admin_delete_user(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: cpf  # Usa o CPF, que é o username
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error "Erro ao deletar usuário no Cognito: #{e.message}"
  end

  def self.update_user(cpf, new_email: nil, new_password: nil)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])

    if new_email.present?
      client.admin_update_user_attributes(
        user_pool_id: ENV['COGNITO_USER_POOL_ID'],
        username: cpf,
        user_attributes: [
          { name: 'email', value: new_email },
          { name: 'email_verified', value: 'true' } # Garante que o novo e-mail esteja verificado
        ]
      )
    end

    if new_password.present?
      client.admin_set_user_password(
        user_pool_id: ENV['COGNITO_USER_POOL_ID'],
        username: cpf,
        password: new_password,
        permanent: true
      )
    end
    true
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    { error: e.message }
  end
end
