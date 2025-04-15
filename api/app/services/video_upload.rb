require 'aws-sdk-s3'

class VideoUpload
  def initialize(video)
    @video = video
    @s3_client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
    @bucket_name = ENV['AWS_S3_BUCKET']
  end

  def call
    file_path = @video.local_path
    file_name = File.basename(file_path)
    upload_path = File.join(Time.now.strftime('%Y/%m/%d'), file_name)

    @s3_client.put_object(
      bucket: @bucket_name,
      key: upload_path,
      body: File.open(file_path)
    )

    @video.update!(
      status: 'armazenado',
      remote_path: "https://#{@bucket_name}/#{upload_path}"
    )

    cleanup_local_file if @video.remote_path.present?
  end

  private

  def cleanup_local_file
    File.delete(@video.local_path) if File.exist?(@video.local_path)
  end
end
