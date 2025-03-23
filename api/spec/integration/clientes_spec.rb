require 'swagger_helper'

RSpec.describe 'Clientes API', swagger_doc: 'v1/swagger.yaml', type: :request do
  path '/clientes' do
    get 'Lista todos os clientes' do
      tags 'Clientes'
      produces 'application/json'

      response '200', 'Lista de clientes retornada com sucesso' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Cliente' }
        run_test!
      end
    end

    post 'Cria um novo cliente' do
      tags 'Clientes'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :cliente, in: :body, schema: { '$ref' => '#/components/schemas/ClienteInput' }

      response '201', 'Cliente criado com sucesso' do
        let(:cliente) { { cliente: attributes_for(:cliente).merge(password: 'SenhaPadrão!') } }
        run_test!
      end

      response '422', 'Dados inválidos' do
        let(:cliente) { { cliente: { nome: '', password: '' } } }
        run_test!
      end
    end
  end

  path '/clientes/{id}' do
    get 'Obtém detalhes de um cliente' do
      tags 'Clientes'
      produces 'application/json'

      parameter name: :id, in: :path, type: :string, description: 'ID do Cliente'

      response '200', 'Cliente encontrado' do
        let(:id) { create(:cliente).id.to_s }
        run_test!
      end

      response '404', 'Cliente não encontrado' do
        let(:id) { 'invalido' }
        run_test!
      end
    end

    patch 'Atualiza um cliente' do
      tags 'Clientes'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :id, in: :path, type: :string, description: 'ID do Cliente'
      parameter name: :cliente, in: :body, schema: { '$ref' => '#/components/schemas/ClienteInput' }

      response '200', 'Cliente atualizado com sucesso' do
        let(:id) { create(:cliente).id.to_s }
        let(:cliente) { { cliente: { nome: 'Novo Nome', email: 'novo@example.com', password: 'NovaSenha@2024' } } }
        run_test!
      end

      response '404', 'Cliente não encontrado' do
        let(:id) { 'invalido' }
        let(:cliente) { { cliente: { nome: 'Novo Nome', password: 'NovaSenha@2024' } } }
        run_test!
      end

      response '422', 'Dados inválidos' do
        let(:id) { create(:cliente).id.to_s }
        let(:cliente) { { cliente: { email: '' } } }
        run_test!
      end
    end
  end

  path '/login' do
    post 'Autentica um cliente via AWS Cognito' do
      tags 'Clientes'
      consumes 'application/json'
      produces 'application/json'
  
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: %w[email password]
      }
  
      response '200', 'Autenticação bem-sucedida' do
        let(:cliente) { create(:cliente) }
        let(:credentials) { { email: cliente.email, password: 'SenhaPadrão!' } }
        run_test!
      end
  
      response '401', 'Credenciais inválidas' do
        let(:credentials) { { email: 'email_invalido@example.com', password: 'senha_errada' } }
        run_test!
      end
  
      response '404', 'Usuário não encontrado no sistema' do
        let(:credentials) { { email: 'nao_existe@example.com', password: 'SenhaPadrão!' } }
        run_test!
      end
    end
  end
end
