require 'aws-sdk-cognitoidentityprovider'

class CognitoAuth
  def self.register(email, password)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    client.admin_create_user(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: email,
      user_attributes: [
        { name: 'email', value: email },
        { name: 'email_verified', value: 'true' }
      ],
      message_action: 'SUPPRESS'
    )
    client.admin_set_user_password(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: email,
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

  def self.valid_token?(access_token)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    begin
      client.get_user(access_token: access_token)
      true
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
           Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      false
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

  def self.update_user(email, new_email: nil, new_password: nil)
    client = Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])

    if new_email.present?
      client.admin_update_user_attributes(
        user_pool_id: ENV['COGNITO_USER_POOL_ID'],
        username: email,
        user_attributes: [
          { name: 'email', value: new_email },
          { name: 'email_verified', value: 'true' }
        ]
      )
    end

    if new_password.present?
      client.admin_set_user_password(
        user_pool_id: ENV['COGNITO_USER_POOL_ID'],
        username: email,
        password: new_password,
        permanent: true
      )
    end
    true
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    { error: e.message }
  end
end
