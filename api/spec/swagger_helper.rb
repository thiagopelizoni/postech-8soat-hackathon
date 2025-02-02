# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API Pedidos',
        version: 'v1'
      },
      paths: {},
      components: {
        schemas: {
          Pedido: {
            type: :object,
            properties: {
              id: { type: :string },
              cliente: {
                type: [:object, 'null'],
                properties: {
                  nome: { type: :string },
                  email: { type: :string },
                  cpf: { type: :integer },
                  token: { type: :string }
                }
              },
              produtos: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    id: { type: :integer },
                    slug: { type: :string },
                    nome: { type: :string },
                    preco: { type: :integer }
                  }
                }
              },
              valor: { type: :integer },
              status: { type: :string },
              observacao: { type: :string },
              data: { type: :string, format: :date_time },
              data_status: { type: :string, format: :date_time },
              pagamento: { type: :string }
            },
            required: %w[id produtos valor status data data_status pagamento]
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
