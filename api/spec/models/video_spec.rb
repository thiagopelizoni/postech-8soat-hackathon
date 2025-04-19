require 'rails_helper'

RSpec.describe Video, type: :model do
  let(:valid_cliente) { Cliente.find_or_create_by(email: 'valid@example.com') { |cliente| cliente.nome = 'Valid Cliente' } }

  describe 'fields and validations' do
    subject { Video.new(local_path: 'path/to/local', remote_path: 'https://example.com/file', status: status, metadados: {}, zip_images: nil, cliente: valid_cliente) }
    valid_statuses = %w[recebido armazenado processado finalizado]

    valid_statuses.each do |valid_status|
      context "when status is #{valid_status}" do
        let(:status) { valid_status }
        it 'is valid' do
          expect(subject).to be_valid
        end
      end
    end

    context 'when status is invalid' do
      let(:status) { 'invalido' }
      it 'is invalid' do
        subject.validate
        expect(subject.errors[:status]).to include("is not included in the list")
      end
    end
  end

  describe 'scopes' do
    before do
      Video.delete_all
      @video_recebido    = Video.create!(local_path: 'local1', remote_path: 'https://example.com/v1', status: 'recebido', metadados: {}, cliente: valid_cliente)
      @video_armazenado  = Video.create!(local_path: 'local2', remote_path: 'https://example.com/v2', status: 'armazenado', metadados: {}, cliente: valid_cliente)
      @video_processado  = Video.create!(local_path: 'local3', remote_path: 'https://example.com/v3', status: 'processado', metadados: {}, cliente: valid_cliente)
      @video_finalizado  = Video.create!(local_path: 'local4', remote_path: 'https://example.com/v4', status: 'finalizado', metadados: {}, cliente: valid_cliente)
    end

    it 'returns recebidos videos' do
      expect(Video.recebidos).to include(@video_recebido)
    end

    it 'returns armazenados videos' do
      expect(Video.armazenados).to include(@video_armazenado)
    end

    it 'returns processados videos' do
      expect(Video.processados).to include(@video_processado)
    end

    it 'returns finalizados videos' do
      expect(Video.finalizados).to include(@video_finalizado)
    end
  end

  describe 'callbacks' do
    let(:cliente) { valid_cliente }
    let(:video)   { Video.create!(local_path: 'local_test', remote_path: remote, status: 'recebido', metadados: {}, zip_images: zip, cliente: cliente) }
    let(:s3_client_double) { instance_double(Aws::S3::Client) }

    before do
      # Stub AWS S3 Client and environment variables
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client_double)
      allow(s3_client_double).to receive(:delete_object)
      stub_const("ENV", ENV.to_hash.merge({
        'AWS_ACCESS_KEY_ID'     => 'ak_test',
        'AWS_SECRET_ACCESS_KEY' => 'sk_test',
        'AWS_REGION'            => 'us-test-1',
        'AWS_S3_BUCKET'         => 'test-bucket'
      }))
    end

    context 'when remote_path and zip_images start with "https://"' do
      let(:remote) { 'https://s3.amazonaws.com/bucket/path/to/file' }
      let(:zip)    { 'https://s3.amazonaws.com/bucket/path/to/zip' }
      it 'calls delete_object for both paths on destroy' do
        video.destroy
        expect(s3_client_double).to have_received(:delete_object).twice
      end
    end

    context 'when paths do not start with "https://"' do
      let(:remote) { 's3://bucket/path/to/file' }
      let(:zip)    { nil }
      it 'does not call delete_object on destroy' do
        video.destroy
        expect(s3_client_double).not_to have_received(:delete_object)
      end
    end
  end
end
