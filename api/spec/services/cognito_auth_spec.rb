require 'rails_helper'
require 'aws-sdk-cognitoidentityprovider'

RSpec.describe CognitoAuth do
  let(:client) { instance_double(Aws::CognitoIdentityProvider::Client) }
  let(:email) { "test@example.com" }
  let(:password) { "SenhaSecreta!2024" }
  let(:cpf) { "12345678901" }
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
        result = CognitoAuth.register(email, password, cpf)
        expect(result).to eq(true)
      end

      it "chama admin_create_user com os parâmetros corretos" do
        CognitoAuth.register(email, password, cpf)
        expect(client).to have_received(:admin_create_user).with(
          user_pool_id: user_pool_id,
          username: cpf,
          user_attributes: [
            { name: 'email', value: email },
            { name: 'email_verified', value: 'true' },
            { name: 'custom:cpf', value: cpf }
          ],
          message_action: 'SUPPRESS'
        )
      end

      it "chama admin_set_user_password com os parâmetros corretos" do
        CognitoAuth.register(email, password, cpf)
        expect(client).to have_received(:admin_set_user_password).with(
          user_pool_id: user_pool_id,
          username: cpf,
          password: password,
          permanent: true
        )
      end
    end

    context "quando ocorre um erro de serviço" do
      before do
        error = Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "erro")
        allow(client).to receive(:admin_create_user).and_raise(error)
      end

      it "retorna um hash com a chave :error" do
        result = CognitoAuth.register(email, password, cpf)
        expect(result).to be_a(Hash)
        expect(result[:error]).to eq("erro")
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

    context "quando o usuário não é autorizado" do
      before do
        error = Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, "não autorizado")
        allow(client).to receive(:initiate_auth).and_raise(error)
      end

      it "retorna nil" do
        expect(CognitoAuth.authenticate(email, password)).to be_nil
      end
    end

    context "quando o usuário não é encontrado" do
      before do
        error = Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new(nil, "usuário não encontrado")
        allow(client).to receive(:initiate_auth).and_raise(error)
      end

      it "retorna nil" do
        expect(CognitoAuth.authenticate(email, password)).to be_nil
      end
    end
  end

  describe ".delete_user" do
    context "quando a exclusão é bem-sucedida" do
      before do
        allow(client).to receive(:admin_delete_user)
      end

      it "chama admin_delete_user com os parâmetros corretos" do
        CognitoAuth.delete_user(cpf)
        expect(client).to have_received(:admin_delete_user).with(
          user_pool_id: user_pool_id,
          username: cpf
        )
      end
    end

    context "quando ocorre um erro ao excluir" do
      before do
        error = Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "erro ao excluir")
        allow(client).to receive(:admin_delete_user).and_raise(error)
        allow(Rails.logger).to receive(:error)
      end

      it "registra o erro no log" do
        CognitoAuth.delete_user(cpf)
        expect(Rails.logger).to have_received(:error).with(/Erro ao deletar usuário no Cognito: erro ao excluir/)
      end
    end
  end

  describe ".update_user" do
    context "quando atualiza o email" do
      before do
        allow(client).to receive(:admin_update_user_attributes)
        allow(client).to receive(:admin_set_user_password)
      end

      it "chama admin_update_user_attributes com os parâmetros corretos" do
        CognitoAuth.update_user(cpf, new_email: email)
        expect(client).to have_received(:admin_update_user_attributes).with(
          user_pool_id: user_pool_id,
          username: cpf,
          user_attributes: [
            { name: 'email', value: email },
            { name: 'email_verified', value: 'true' }
          ]
        )
      end

      it "retorna true" do
        result = CognitoAuth.update_user(cpf, new_email: email)
        expect(result).to eq(true)
      end
    end

    context "quando atualiza a senha" do
      before do
        allow(client).to receive(:admin_update_user_attributes)
        allow(client).to receive(:admin_set_user_password)
      end

      it "chama admin_set_user_password com os parâmetros corretos" do
        CognitoAuth.update_user(cpf, new_password: password)
        expect(client).to have_received(:admin_set_user_password).with(
          user_pool_id: user_pool_id,
          username: cpf,
          password: password,
          permanent: true
        )
      end

      it "retorna true" do
        result = CognitoAuth.update_user(cpf, new_password: password)
        expect(result).to eq(true)
      end
    end

    context "quando ocorre erro durante a atualização" do
      before do
        error = Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "erro de atualização")
        allow(client).to receive(:admin_update_user_attributes).and_raise(error)
      end

      it "retorna um hash com a chave :error" do
        result = CognitoAuth.update_user(cpf, new_email: email)
        expect(result).to be_a(Hash)
        expect(result[:error]).to eq("erro de atualização")
      end
    end
  end
end
