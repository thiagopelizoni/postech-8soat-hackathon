require 'aws-sdk-cognitoidentityprovider'

class CognitoAuth
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
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
      nil
    rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      nil
    end
  end
end
