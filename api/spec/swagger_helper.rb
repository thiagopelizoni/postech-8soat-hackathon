# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Hackathon API',
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
          },
          Video: {
            type: :object,
            properties: {
              local_path: { type: :string, description: 'Caminho local do vídeo' },
              remote_path: { type: :string, description: 'Caminho remoto do vídeo' },
              status: { type: :string, description: 'Status do vídeo', enum: %w[recebido armazenado processado finalizado] },
              metadados: {
                type: :object,
                description: 'Metadados do vídeo',
                properties: {
                  duration: { type: :number, description: 'Duração do vídeo' },
                  bitrate: { type: :number, description: 'Taxa de bits do vídeo' },
                  resolution: { type: :string, description: 'Resolução do vídeo' },
                  video_stream: { type: :string, description: 'Stream de vídeo' },
                  audio_stream: { type: :string, description: 'Stream de áudio' }
                }
              },
              cliente_id: { type: :string, description: 'ID do cliente associado' }
            },
            required: %w[local_path status metadados cliente_id]
          },
          VideoInput: {
            type: :object,
            properties: {
              video: {
                '$ref' => '#/components/schemas/Video'
              }
            },
            required: ['video']
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
