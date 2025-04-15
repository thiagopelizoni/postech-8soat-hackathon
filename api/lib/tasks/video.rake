namespace :video do
  desc "Carregar vídeos recebidos para o S3 e atualizar seus status"
  task upload: :environment do
    logger = Logger.new(STDOUT)
    Video.recebidos.each do |video|
      begin
        VideoUpload.new(video).call
        logger.info("Vídeo #{video.id} carregado para o S3, status atualizado para 'armazenado' e arquivo local removido.")
      rescue => e
        logger.error("Falha ao carregar #{video.id} para o S3: #{e.message}")
      end
    end
  end

  desc "Processar vídeos armazenados extraindo frames e carregando um ZIP de imagens"
  task process: :environment do
    logger = Logger.new(STDOUT)
    Video.armazenados.each do |video|
      begin
        VideoProcessor.new(video).call
        logger.info("Vídeo #{video.id} processado, frames extraídos e ZIP de imagens carregado.")
      rescue => e
        logger.error("Falha ao processar o vídeo #{video.id}: #{e.message}")
      end
    end
  end

  desc "Enviar email com link do arquivo ZIP para ser baixado"
  task email_notification: :environment do
    logger = Logger.new(STDOUT)
    Video.processados.each do |video|
      begin
        VideoMailer.email_notification(video).deliver_now
        logger.info("Email enviado com sucesso para o vídeo #{video.id}.")
      rescue => e
        logger.error("Falha ao enviar email para o vídeo #{video.id}: #{e.message}")
      end
    end
  end
end