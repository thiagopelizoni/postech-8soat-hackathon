require 'rails_helper'
require 'tempfile'

RSpec.describe VideoUpload, type: :service do
  let(:dummy_mp4) do
    file = Tempfile.new(['dummy', '.mp4'])
    file.write("dummy content")
    file.rewind
    file.path
  end
  
  let(:video) do
    double("Video", 
      local_path: dummy_mp4, 
      update!: nil,
      remote_path: nil
    )
  end
  
  let(:s3_client_double) { instance_double(Aws::S3::Client) }
  let(:bucket_name) { "test-bucket" }
  subject { VideoUpload.new(video) }

  before do
    stub_const("ENV", ENV.to_h.merge(
      'AWS_ACCESS_KEY_ID'     => 'test_key',
      'AWS_SECRET_ACCESS_KEY' => 'test_secret',
      'AWS_REGION'            => 'us-test-1',
      'AWS_S3_BUCKET'         => bucket_name
    ))
    allow(Aws::S3::Client).to receive(:new).and_return(s3_client_double)
    allow(s3_client_double).to receive(:put_object)
    allow(video).to receive(:update!) do |params|
      allow(video).to receive(:remote_path).and_return(params[:remote_path])
    end
    File.write(dummy_mp4, "dummy content")
  end

  after do
    File.delete(dummy_mp4) if File.exist?(dummy_mp4)
  end

  describe "#call" do
    it "faz upload do arquivo para o S3, atualiza o status e remove o arquivo local" do
      now_str = Time.now.strftime('%Y/%m/%d')
      expected_key = File.join(now_str, File.basename(dummy_mp4))
      
      expect(s3_client_double).to receive(:put_object).with(hash_including(
        bucket: bucket_name,
        key: expected_key
      ))
      expect(video).to receive(:update!).with(hash_including(
        status: 'armazenado',
        remote_path: a_string_starting_with("https://#{bucket_name}/")
      ))
      
      subject.call
      
      expect(File).not_to exist(dummy_mp4)
    end
  end
end
