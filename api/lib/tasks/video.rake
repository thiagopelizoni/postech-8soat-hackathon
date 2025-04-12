namespace :video do
  desc "Carregar vídeos recebidos para o S3 e atualizar seus status"
  task upload: :environment do
    logger = Logger.new(STDOUT)
    Video.recebidos.each do |video|
      begin
        VideoUpload.new(video).call
        logger.info("Vídeo #{video.local_path} carregado para o S3, status atualizado para 'armazenado' e arquivo local removido.")
      rescue => e
        logger.error("Falha ao carregar #{video.local_path} para o S3: #{e.message}")
      end
    end
  end

  desc "Processar vídeos armazenados extraindo frames e carregando um ZIP de imagens"
  task process: :environment do
    logger = Logger.new(STDOUT)
    Video.armazenados.each do |video|
      begin
        VideoProcessor.new(video).call
        logger.info("Vídeo #{video.remote_path} processado, frames extraídos e ZIP de imagens carregado.")
      rescue => e
        logger.error("Falha ao processar o vídeo #{video.remote_path}: #{e.message}")
      end
    end
  end
end