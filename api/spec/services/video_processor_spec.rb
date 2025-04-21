require 'rails_helper'
require 'tempfile'
require 'fileutils'
require 'zip'

RSpec.describe VideoProcessor, type: :service do
  let(:dummy_mp4) do
    file = Tempfile.new(['dummy_video', '.mp4'])
    file.write("dummy video content")
    file.rewind
    file.path
  end
  
  let(:video) do
    # Define remote_path dummy e metadados com video_stream simulando "30 fps"
    double("Video",
      id: 123, # Adiciona o método id ao double
      remote_path: "https://test-bucket/path/to/dummy_video.mp4",
      metadados: { 'video_stream' => "30 fps" },
      update!: nil
    )
  end
  
  let(:s3_client_double) { instance_double(Aws::S3::Client) }
  let(:bucket_name) { "test-bucket" }
  subject { VideoProcessor.new(video) }
  let(:tmp_dir) { Dir.mktmpdir }

  before do
    stub_const("ENV", ENV.to_h.merge(
      'AWS_ACCESS_KEY_ID'     => 'test_key',
      'AWS_SECRET_ACCESS_KEY' => 'test_secret',
      'AWS_REGION'            => 'us-test-1',
      'AWS_S3_BUCKET'         => bucket_name
    ))
    allow(Aws::S3::Client).to receive(:new).and_return(s3_client_double)

    # Stub para download do vídeo: simula escrita do conteúdo (usando bloco)
    allow(s3_client_double).to receive(:get_object) do |args, &block|
      block.call("dummy video content")
    end

    # Stub para o upload do ZIP
    allow(s3_client_double).to receive(:put_object)
    allow(video).to receive(:update!)
    
    # Stub para simular a execução do ffmpeg via backticks
    allow(subject).to receive(:`).and_return("ffmpeg success")
    allow($?).to receive(:success?).and_return(true)
    
    # Força o Dir.tmpdir para um diretório controlado
    allow(Dir).to receive(:tmpdir).and_return(tmp_dir)
    
    # Cria um arquivo dummy que simula o vídeo baixado
    @downloaded_video = File.join(tmp_dir, File.basename(video.remote_path))
    File.write(@downloaded_video, "dummy video content")
    
    # Stub para garantir que a extração de frames retorne um frame dummy
    dummy_frame = File.join(tmp_dir, "frame_0001.jpg")
    File.write(dummy_frame, "dummy frame")
    allow(Dir).to receive(:glob).and_return([dummy_frame])
    
    # Garante que $? não seja nil, stube o success? com valor true
    allow($?).to receive(:success?).and_return(true)
  end

  after do
    FileUtils.remove_entry(tmp_dir) if Dir.exist?(tmp_dir)
  end

  describe "#call" do
    context "quando o processamento ocorre com sucesso" do
      it "executa download, extração de frames, criação de ZIP, upload e atualiza status e zip_images" do
        expect(s3_client_double).to receive(:get_object).with(hash_including(bucket: bucket_name))
        expect(s3_client_double).to receive(:put_object).with(hash_including(bucket: bucket_name, key: a_string_ending_with('.zip')))
        expect(video).to receive(:update!).with(hash_including(zip_images: a_string_starting_with("https://#{bucket_name}/")))
        expect(video).to receive(:update!).with(status: 'processado')

        subject.call

        # Verifica que os arquivos temporários foram limpos
        expect(File).not_to exist(@downloaded_video)
      end
    end

    context "quando a extração de frames falha" do
      before do
        allow(subject).to receive(:`).and_return("error output")
        allow($?).to receive(:success?).and_return(false)
      end

      it "lança RuntimeError com mensagem de falha na extração" do
        expect { subject.call }.to raise_error(RuntimeError, /Falha na extração de frames/)
      end
    end
  end
end
