require 'rails_helper'
require 'aws-sdk-cognitoidentityprovider'

RSpec.describe CognitoAuth do
  let(:client) { instance_double(Aws::CognitoIdentityProvider::Client) }
  let(:email) { "test@example.com" }
  let(:password) { "SenhaSecreta!2024" }
  let(:user_pool_id) { "us-east-1_examplePool" }
  let(:client_id) { "exampleClientId" }

  before do
    stub_const("ENV", ENV.to_h.merge(
      "AWS_REGION" => "us-east-1",
      "COGNITO_USER_POOL_ID" => user_pool_id,
      "COGNITO_USER_POOL_CLIENT_ID" => client_id
    ))
    allow(Aws::CognitoIdentityProvider::Client).to receive(:new).and_return(client)
  end

  describe ".register" do
    context "quando o cadastro é bem-sucedido" do
      before do
        allow(client).to receive(:admin_create_user)
        allow(client).to receive(:admin_set_user_password)
      end

      it "retorna true" do
        result = CognitoAuth.register(email, password)
        expect(result).to eq(true)
      end

      it "chama admin_create_user com os parâmetros corretos" do
        CognitoAuth.register(email, password)
        expect(client).to have_received(:admin_create_user).with(
          user_pool_id: user_pool_id,
          username: email,
          user_attributes: [
            { name: 'email', value: email },
            { name: 'email_verified', value: 'true' }
          ],
          message_action: 'SUPPRESS'
        )
      end
    end
  end

  describe ".authenticate" do
    context "quando a autenticação é bem-sucedida" do
      let(:auth_result) do
        instance_double(Aws::CognitoIdentityProvider::Types::AuthenticationResultType,
          id_token: "id-token", access_token: "access-token", refresh_token: "refresh-token")
      end
      let(:resp) { double("resp", authentication_result: auth_result) }

      before do
        allow(client).to receive(:initiate_auth).and_return(resp)
      end

      it "retorna um hash com os tokens" do
        result = CognitoAuth.authenticate(email, password)
        expect(result).to eq({
          id_token: "id-token",
          access_token: "access-token",
          refresh_token: "refresh-token"
        })
      end
    end
  end

  describe ".delete_user" do
    context "quando a exclusão é bem-sucedida" do
      before do
        allow(client).to receive(:admin_delete_user)
      end

      it "chama admin_delete_user com os parâmetros corretos" do
        CognitoAuth.delete_user(email)
        expect(client).to have_received(:admin_delete_user).with(
          user_pool_id: user_pool_id,
          username: email
        )
      end
    end
  end

  describe ".update_user" do
    context "quando atualiza o email" do
      before do
        allow(client).to receive(:admin_update_user_attributes)
      end

      it "chama admin_update_user_attributes com os parâmetros corretos" do
        CognitoAuth.update_user(email, new_email: "novo@example.com")
        expect(client).to have_received(:admin_update_user_attributes).with(
          user_pool_id: user_pool_id,
          username: email,
          user_attributes: [
            { name: 'email', value: "novo@example.com" },
            { name: 'email_verified', value: 'true' }
          ]
        )
      end
    end
  end
end