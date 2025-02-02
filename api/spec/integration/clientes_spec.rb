require 'swagger_helper'

RSpec.describe 'Clientes API', type: :request do
  path '/clientes' do
    get 'Lista todos os clientes' do
      tags 'Clientes'
      produces 'application/json'

      response '200', 'Lista de clientes retornada com sucesso' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Cliente' }

        before { create_list(:cliente, 3) }

        run_test!
      end
    end

    post 'Cria um novo cliente' do
      tags 'Clientes'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :cliente, in: :body, schema: {
        type: :object,
        properties: {
          nome: { type: :string },
          data_nascimento: { type: :string, format: :date },
          cpf: { type: :string },
          email: { type: :string, format: :email }
        },
        required: %w[nome data_nascimento cpf email]
      }

      response '201', 'Cliente criado com sucesso' do
        let(:cliente) { attributes_for(:cliente) }
        run_test!
      end

      response '422', 'Dados inválidos' do
        let(:cliente) { { nome: '', cpf: '123' } }
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
      parameter name: :cliente, in: :body, schema: {
        type: :object,
        properties: {
          nome: { type: :string },
          email: { type: :string, format: :email }
        }
      }

      response '200', 'Cliente atualizado com sucesso' do
        let(:id) { create(:cliente).id.to_s }
        let(:cliente) { { nome: 'Novo Nome' } }
        run_test!
      end

      response '404', 'Cliente não encontrado' do
        let(:id) { 'invalido' }
        let(:cliente) { { nome: 'Novo Nome' } }
        run_test!
      end

      response '422', 'Dados inválidos' do
        let(:id) { create(:cliente).id.to_s }
        let(:cliente) { { cpf: '123' } }
        run_test!
      end
    end
  end
end
