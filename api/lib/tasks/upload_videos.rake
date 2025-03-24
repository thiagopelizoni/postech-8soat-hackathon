require 'aws-sdk-s3'

namespace :videos do
  desc "Upload received videos to S3 and update their status"
  task upload_to_s3: :environment do
    s3_client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_DEFAULT_REGION']
    )

    bucket_name = ENV['AWS_S3_BUCKET']

    Video.where(status: 'recebido').each do |video|
      begin
        file_path = video.local_path
        file_name = File.basename(file_path)
        upload_path = File.join(Time.now.strftime('%Y/%m/%d'), file_name)

        s3_client.put_object(
          bucket: bucket_name,
          key: upload_path,
          body: File.open(file_path)
        )

        video.update!(
          status: 'armazenado',
          remote_path: "https://#{bucket_name}.s3.amazonaws.com/#{upload_path}"
        )

        if video.remote_path.present?
          File.delete(file_path) if File.exist?(file_path)
          video.update!(local_path: nil)
        end

        puts "Uploaded #{file_name} to S3, updated video status to 'armazenado', and removed local file."
      rescue => e
        puts "Failed to upload #{file_name} to S3: #{e.message}"
      end
    end
  end
end