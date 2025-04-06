require 'faker'
require 'aws-sdk-cognitoidentityprovider'

USER_POOL_ID = ENV.fetch('COGNITO_USER_POOL_ID')
AWS_REGION = ENV.fetch('AWS_REGION', 'us-east-1')

credentials = Aws::Credentials.new(
  ENV.fetch('AWS_ACCESS_KEY_ID'),
  ENV.fetch('AWS_SECRET_ACCESS_KEY')
)

cognito_client = Aws::CognitoIdentityProvider::Client.new(region: AWS_REGION, credentials: credentials)

clientes = []

10.times do |i|
  nome = Faker::Name.name
  email = Faker::Internet.email
  password = ENV.fetch('COGNITO_PASSWORD')

  begin
    cognito_client.admin_create_user(
      user_pool_id: USER_POOL_ID,
      username: email,
      user_attributes: [
        { name: 'email', value: email },
        { name: 'email_verified', value: 'true' },
        { name: 'name', value: nome }
      ],
      temporary_password: password,
      message_action: 'SUPPRESS'
    )

    cognito_client.admin_set_user_password(
      user_pool_id: USER_POOL_ID,
      username: email,
      password: password,
      permanent: true
    )
  rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException
    puts "Usuário já existe no Cognito: Email #{email}"
  rescue Aws::CognitoIdentityProvider::Errors::LimitExceededException
    sleep 2
    retry
  end

  clientes << {
    nome: nome,
    email: email
  }

  sleep 0.2 if i % 10 == 0
end

Cliente.create!(clientes)

puts "Clientes gerados e cadastrados no Cognito sem envio de e-mail!"
