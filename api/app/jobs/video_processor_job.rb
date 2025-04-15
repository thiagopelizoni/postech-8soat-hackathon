
class VideoProcessorJob < ApplicationJob
    queue_as :video_process
  
    def perform(video_id)
      video = Video.find(video_id)
      VideoProcessor.new(video).call
      VideoNotificationJob.perform_later(video.id)
    rescue => e
      Rails.logger.error "Falha no VideoProcessorJob para o vídeo #{video_id}: #{e.message}"
      raise e
    end
  end
  