class VideoNotificationJob < ApplicationJob
    queue_as :video_notification
  
    def perform(video_id)
      video = Video.find(video_id)
      VideoMailer.email_notification(video).deliver_now
      video.update!(status: 'finalizado')
    rescue => e
      Rails.logger.error "Falha no VideoNotificationJob para o vídeo #{video_id}: #{e.message}"
      raise e
    end
  end
  