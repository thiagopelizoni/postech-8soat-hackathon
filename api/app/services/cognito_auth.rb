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
      resp.authentication_result['IdToken']
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
      nil
    rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      nil
    end
  end
end
