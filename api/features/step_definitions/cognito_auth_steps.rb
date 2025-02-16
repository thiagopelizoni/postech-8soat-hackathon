require 'aws-sdk-cognitoidentityprovider'
require 'cucumber/rails'
require 'rspec/mocks'

include RSpec::Mocks::ExampleMethods

Before do
  RSpec::Mocks.setup
end

After do
  RSpec::Mocks.verify
  RSpec::Mocks.teardown
end

# Configuração das variáveis de ambiente
Given(/^the AWS region is set to "([^"]*)"$/) do |region|
  ENV['AWS_REGION'] = region
end

Given(/^the COGNITO_USER_POOL_ID is set to "([^"]*)"$/) do |pool_id|
  ENV['COGNITO_USER_POOL_ID'] = pool_id
end

Given(/^the COGNITO_USER_POOL_CLIENT_ID is set to "([^"]*)"$/) do |client_id|
  ENV['COGNITO_USER_POOL_CLIENT_ID'] = client_id
end

Given(/^Cognito register will fail with error "([^"]*)"$/) do |error_message|
  @aws_client = instance_double(Aws::CognitoIdentityProvider::Client)
  allow(@aws_client).to receive(:admin_create_user).and_raise(
    Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, error_message)
  )
  allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(@aws_client)
end

When(/^I register a user with email "([^"]*)", password "([^"]*)", and cpf "([^"]*)"$/) do |email, password, cpf|
  unless defined?(@aws_client) && @aws_client
    @aws_client = instance_double(Aws::CognitoIdentityProvider::Client)
    allow(@aws_client).to receive(:admin_create_user).and_return(true)
    allow(@aws_client).to receive(:admin_set_user_password).and_return(true)
    allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(@aws_client)
  end
  @result = CognitoAuth.register(email, password, cpf)
end

Then(/^the registration result should be true$/) do
  expect(@result).to eq(true)
end

Then(/^the registration result should be an error with message "([^"]*)"$/) do |msg|
  expect(@result).to be_a(Hash)
  expect(@result[:error]).to eq(msg)
end

# ----- Cenários de Autenticação -----
Given(/^Cognito authenticate will return tokens:$/) do |table|
  tokens = table.rows_hash
  # Cria um objeto fake de authentication_result
  fake_auth_result = double("AuthenticationResult", 
                             id_token: tokens["id_token"], 
                             access_token: tokens["access_token"], 
                             refresh_token: tokens["refresh_token"])
  fake_resp = double("Response", authentication_result: fake_auth_result)
  @aws_client = instance_double(Aws::CognitoIdentityProvider::Client)
  allow(@aws_client).to receive(:initiate_auth).and_return(fake_resp)
  allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(@aws_client)
end

Given(/^Cognito authenticate will fail$/) do
  @aws_client = instance_double(Aws::CognitoIdentityProvider::Client)
  allow(@aws_client).to receive(:initiate_auth).and_raise(
    Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, "Not authorized")
  )
  allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(@aws_client)
end

When(/^I authenticate with email "([^"]*)" and password "([^"]*)"$/) do |email, password|
  @auth_result = CognitoAuth.authenticate(email, password)
end

Then(/^the authentication result should include token "([^"]*)" for "([^"]*)"$/) do |token, key|
  expect(@auth_result).to include(key.to_sym => token)
end

Then(/^the authentication result should be nil$/) do
  expect(@auth_result).to be_nil
end

Given(/^Cognito delete user will succeed$/) do
  @aws_client = instance_double(Aws::CognitoIdentityProvider::Client)
  allow(@aws_client).to receive(:admin_delete_user).and_return(true)
  allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(@aws_client)
end

When(/^I delete user with cpf "([^"]*)"$/) do |cpf|
  begin
    CognitoAuth.delete_user(cpf)
    @delete_error = nil
  rescue => e
    @delete_error = e
  end
end

Then(/^no error should be raised$/) do
  expect(@delete_error).to be_nil
end

Given(/^Cognito update user will succeed$/) do
  @aws_client = instance_double(Aws::CognitoIdentityProvider::Client)
  # Stub para quando atualizar email e senha com sucesso
  allow(@aws_client).to receive(:admin_update_user_attributes).and_return(true)
  allow(@aws_client).to receive(:admin_set_user_password).and_return(true)
  allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(@aws_client)
end

Given(/^Cognito update user will fail with error "([^"]*)"$/) do |error_message|
  @aws_client = instance_double(Aws::CognitoIdentityProvider::Client)
  allow(@aws_client).to receive(:admin_update_user_attributes).and_raise(
    Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, error_message)
  )
  allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(@aws_client)
end

When(/^I update user with cpf "([^"]*)", new email "([^"]*)" and new password "([^"]*)"$/) do |cpf, new_email, new_password|
  @update_result = CognitoAuth.update_user(cpf, new_email: new_email, new_password: new_password)
end

Then(/^the update result should be true$/) do
  expect(@update_result).to eq(true)
end

Then(/^the update result should be an error with message "([^"]*)"$/) do |msg|
  expect(@update_result).to be_a(Hash)
  expect(@update_result[:error]).to eq(msg)
end
