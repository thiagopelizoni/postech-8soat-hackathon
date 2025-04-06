require 'aws-sdk-s3'

namespace :videos do
  desc "Upload received videos to S3 and update their status"
  task upload: :environment do
    Video.recebidos.each do |video|
      begin
        VideoUpload.new(video).call
        puts "Uploaded #{video.local_path} to S3, updated video status to 'armazenado', and removed local file."
      rescue => e
        puts "Failed to upload #{video.local_path} to S3: #{e.message}"
      end
    end
  end
end