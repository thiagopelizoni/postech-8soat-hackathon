require 'swagger_helper'

RSpec.describe 'Clientes API', type: :request do
  path '/clientes' do
    get 'Lista todos os clientes' do
      tags 'Clientes'
      produces 'application/json'

      response '200', 'Lista de clientes retornada com sucesso' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Cliente' }

        before { create_list(:cliente, 3) }
      end
    end

    post 'Cria um novo cliente' do
      tags 'Clientes'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :cliente, in: :body, schema: { '$ref' => '#/components/schemas/ClienteInput' }

      response '201', 'Cliente criado com sucesso' do
        let(:cliente) { { cliente: attributes_for(:cliente).merge(password: 'SenhaPadrão!') } }
        
      end

      response '422', 'Dados inválidos' do
        let(:cliente) { { cliente: { nome: '', cpf: '123', password: '' } } }
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
      end

      response '404', 'Cliente não encontrado' do
        let(:id) { 'invalido' }
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
      end

      response '404', 'Cliente não encontrado' do
        let(:id) { 'invalido' }
        let(:cliente) { { cliente: { nome: 'Novo Nome', password: 'NovaSenha@2024' } } }
      end

      response '422', 'Dados inválidos' do
        let(:id) { create(:cliente).id.to_s }
        let(:cliente) { { cliente: { cpf: '123' } } }
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
          cpf: { type: :string },
          password: { type: :string }
        },
        required: %w[cpf password]
      }
  
      response '200', 'Autenticação bem-sucedida' do
        let(:cliente) { create(:cliente) }
        let(:credentials) { { cpf: cliente.cpf, password: 'SenhaPadrão!' } }
      end
  
      response '401', 'Credenciais inválidas' do
        let(:credentials) { { cpf: '12345678901', password: 'senha_errada' } }
      end
  
      response '404', 'Usuário não encontrado no sistema' do
        let(:credentials) { { cpf: '00000000000', password: 'SenhaPadrão!' } }
      end
    end
  end
end
