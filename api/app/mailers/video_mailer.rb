class VideoMailer < ApplicationMailer
  def email_notification(video)
    @video = video
    @client_name = video.cliente.nome
    @download_link = video.zip_images

    mail(
      to: video.cliente.email,
      subject: "As imagens do seu vídeo já foram processadas e encontram-se disponíveis para download."
    )
  end
end