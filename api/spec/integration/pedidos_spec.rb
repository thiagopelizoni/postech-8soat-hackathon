require 'swagger_helper'

RSpec.describe 'Pedidos API', type: :request do
  path '/pedidos' do
    get 'Listar Pedidos' do
      parameter name: :page, in: :query, type: :integer, description: 'Número da página'
      parameter name: :per_page, in: :query, type: :integer, description: 'Número de itens por página'
      tags 'Pedidos'
      produces 'application/json'
      
      response '200', 'pedidos encontrados' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Pedido' }
        run_test!
      end
    end

    post 'Criar Pedido' do
      tags 'Pedidos'
      consumes 'application/json'
      parameter name: :pedido, in: :body, schema: {
        '$ref' => '#/components/schemas/Pedido'
      }
      
      response '201', 'pedido criado' do
        schema '$ref' => '#/components/schemas/Pedido'
        let(:pedido) do
          { 
            cliente: { nome: 'Cliente Teste', email: 'cliente@example.com', cpf: '12345678900', token: 'abc123' },
            produtos: [{ id: 1, slug: 'brownie', nome: 'Brownie', preco: 9 }],
            pagamento: 'em_aberto',
            status: 'recebido'
          }
        end
        run_test!
      end
    end
  end

  path '/pedidos/{id}' do
    get 'Exibir Pedido' do
      tags 'Pedidos'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string

      response '200', 'pedido encontrado' do
        schema '$ref' => '#/components/schemas/Pedido'
        let(:id) { create(:pedido).id }
        run_test!
      end
    end

    put 'Atualizar Pedido' do
      tags 'Pedidos'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :pedido, in: :body, schema: {
        '$ref' => '#/components/schemas/Pedido'
      }

      response '200', 'pedido atualizado' do
        schema '$ref' => '#/components/schemas/Pedido'
        let(:id) { create(:pedido).id }
        let(:pedido) do
          {
            cliente: { nome: 'Cliente Atualizado', email: 'atualizado@example.com', cpf: '98765432100', token: 'xyz789' },
            produtos: [{ id: 2, slug: 'cheeseburger', nome: 'Cheeseburger', preco: 10 }],
            pagamento: 'confirmado',
            status: 'pronto'
          }
        end
        run_test!
      end
    end
  end

  %w[prontos recebidos em-preparacao finalizados pagamento-confirmado pagamento-em-aberto pagamento-recusado].each do |action|
    path "/pedidos/#{action}" do
      get "Listar pedidos #{action.tr('-', ' ')}" do
        tags 'Pedidos'
        produces 'application/json'
        response '200', 'pedidos encontrados' do
          schema type: :array, items: { '$ref' => '#/components/schemas/Pedido' }
          run_test!
        end
      end
    end
  end

  %w[pagar receber preparar pronto finalizar].each do |action|
    path "/pedidos/{id}/#{action}" do
      put "Atualizar pedido para #{action}" do
        tags 'Pedidos'
        parameter name: :id, in: :path, type: :string
        response '200', 'pedido atualizado' do
          let(:id) { create(:pedido).id }
          run_test!
        end
      end
    end
  end

  path '/pedidos/{id}/qr-code' do
    get 'Obter QR Code de pagamento' do
      tags 'Pedidos'
      parameter name: :id, in: :path, type: :string
      response '200', 'QR Code gerado' do
        run_test!
      end
    end
  end
end
