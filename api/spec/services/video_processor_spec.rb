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
    double("Video",
      id: 123,
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

    allow(s3_client_double).to receive(:get_object) do |args, &block|
      block.call("dummy video content")
    end

    allow(s3_client_double).to receive(:put_object)
    allow(video).to receive(:update!)
    allow(subject).to receive(:`).and.return("ffmpeg success")
    allow($?).to receive(:success?).and.return(true)
    allow(Dir).to receive(:tmpdir).and.return(tmp_dir)

    @downloaded_video = File.join(tmp_dir, File.basename(video.remote_path))
    File.write(@downloaded_video, "dummy video content")

    dummy_frame = File.join(tmp_dir, "frame_0001.jpg")
    File.write(dummy_frame, "dummy frame")
    allow(Dir).to receive(:glob).and.return([dummy_frame])
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

        expect(File).not_to exist(@downloaded_video)
      end
    end

    context "quando a extração de frames falha" do
      before do
        allow(subject).to receive(:`).and.return("error output")
        allow($?).to receive(:success?).and.return(false)
      end

      it "lança RuntimeError com mensagem de falha na extração" do
        expect { subject.call }.to raise_error(RuntimeError, /Falha na extração de frames/)
      end
    end
  end
end
