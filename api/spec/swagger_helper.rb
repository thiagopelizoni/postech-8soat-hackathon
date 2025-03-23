# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Hackathon',
        version: 'v1'
      },
      paths: {},
      components: {
        schemas: {
          Cliente: {
            type: :object,
            properties: {
              nome: { type: :string, description: 'Nome completo do Cliente' },              
              email: { type: :string, format: :email, description: 'E-mail do Cliente' },
              password: { type: :string, description: 'Senha do Cliente' }
            },
            required: %w[nome email password]
          },
          ClienteInput: {
            type: :object,
            properties: {
              cliente: {
                '$ref' => '#/components/schemas/Cliente'
              }
            },
            required: ['cliente']
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
