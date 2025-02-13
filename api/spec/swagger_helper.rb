# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API Clientes',
        version: 'v1'
      },
      paths: {},
      components: {
        schemas: {
          Cliente: {
            type: :object,
            properties: {
              id: { type: :string, description: 'ID do Cliente' },
              nome: { type: :string, description: 'Nome completo do Cliente' },
              data_nascimento: { type: :string, format: :date, description: 'Data de nascimento do Cliente (YYYY-MM-DD)' },
              cpf: { type: :string, description: 'CPF do Cliente (11 dígitos, sem formatação)', example: '12345678901' },
              email: { type: :string, format: :email, description: 'E-mail do Cliente' },
              password: { type: :string, description: 'Senha do Cliente' }
            },
            required: %w[nome data_nascimento cpf email password]
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
