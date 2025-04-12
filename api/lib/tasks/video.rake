namespace :video do
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

  desc "Process stored videos by extracting frames and uploading a ZIP of images"
  task process: :environment do
    Video.armazenados.each do |video|
      #begin
        VideoProcessor.new(video).call
        puts "Processed video #{video.remote_path}, extracted frames, and uploaded ZIP of images."
     # rescue => e
        puts "Failed to process video #{video.remote_path}: #{e.message}"
      #end
    end
  end
end