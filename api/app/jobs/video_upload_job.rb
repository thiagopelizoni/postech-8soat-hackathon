class VideoUploadJob < ApplicationJob
  queue_as :video_upload

  def perform(video_id)
    Rails.logger.info "Iniciando VideoUploadJob para o vídeo #{video_id}"
    video = Video.find(video_id)
    VideoUpload.new(video).call
    VideoProcessorJob.perform_later(video.id)
    Rails.logger.info "VideoUploadJob concluído para o vídeo #{video_id}"
  rescue => e
    Rails.logger.error "Falha no VideoUploadJob para o vídeo #{video_id}: #{e.message}"
    raise e
  end
end
