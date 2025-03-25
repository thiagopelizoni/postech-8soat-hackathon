require 'swagger_helper'

RSpec.describe 'Videos API', swagger_doc: 'v1/swagger.yaml', type: :request do
  path '/videos' do
    get 'Lista todos os vídeos' do
      tags 'Videos'
      produces 'application/json'

      response '200', 'Lista de vídeos retornada com sucesso' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Video' }
        run_test!
      end
    end

    post 'Cria um novo vídeo' do
      tags 'Videos'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Token de autenticação'
      parameter name: :arquivo, in: :formData, type: :file, description: 'Arquivo de vídeo a ser enviado'

      response '201', 'Vídeo criado com sucesso' do
        description <<~DESC
          Exemplo de cURL para envio do vídeo: \\
          curl -X POST "http://localhost:3000/videos" \\
            -H "Authorization: Bearer SEU_TOKEN_AQUI" \\
            -H "Content-Type: multipart/form-data" \\
            -F "arquivo=@/caminho/para/seu/video.mp4"
        DESC
        let(:arquivo) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'video.mp4'), 'video/mp4') }
        run_test!
      end

      response '400', 'Arquivo de vídeo é obrigatório' do
        let(:arquivo) { nil }
        run_test!
      end

      response '401', 'Não autorizado' do
        let(:arquivo) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'video.mp4'), 'video/mp4') }
        run_test!
      end

      response '422', 'Dados inválidos' do
        let(:arquivo) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'video_invalido.mp4'), 'video/mp4') }
        run_test!
      end
    end
  end

  path '/videos/{id}' do
    get 'Obtém detalhes de um vídeo' do
      tags 'Videos'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID do Vídeo'

      response '200', 'Vídeo encontrado' do
        let(:id) { create(:video).id.to_s }
        run_test!
      end

      response '404', 'Vídeo não encontrado' do
        let(:id) { 'invalido' }
        run_test!
      end
    end

    patch 'Atualiza um vídeo' do
      tags 'Videos'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID do Vídeo'
      parameter name: :video, in: :body, schema: { '$ref' => '#/components/schemas/VideoInput' }

      response '200', 'Vídeo atualizado com sucesso' do
        let(:id) { create(:video).id.to_s }
        let(:video) { { video: { status: 'processado' } } }
        run_test!
      end

      response '404', 'Vídeo não encontrado' do
        let(:id) { 'invalido' }
        let(:video) { { video: { status: 'processado' } } }
        run_test!
      end

      response '422', 'Dados inválidos' do
        let(:id) { create(:video).id.to_s }
        let(:video) { { video: { status: '' } } }
        run_test!
      end
    end

    delete 'Remove um vídeo' do
      tags 'Videos'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID do Vídeo'

      response '204', 'Vídeo removido com sucesso' do
        let(:id) { create(:video).id.to_s }
        run_test!
      end

      response '404', 'Vídeo não encontrado' do
        let(:id) { 'invalido' }
        run_test!
      end
    end
  end
end