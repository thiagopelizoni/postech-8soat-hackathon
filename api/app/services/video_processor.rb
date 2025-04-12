require 'aws-sdk-s3'
require 'zip'
require 'logger'

class VideoProcessor
  def initialize(video)
    @video = video
    @logger = Logger.new(STDOUT)
    @s3_client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
    @bucket_name = ENV['AWS_S3_BUCKET']
  end

  def call
    @logger.info("Iniciando processamento do vídeo: #{@video.remote_path}")
    download_video
    @logger.info("Download do vídeo concluído: #{@local_video_path}")
    extract_frames
    @logger.info("Extração de frames concluída: #{@frames_dir}")
    create_zip
    @logger.info("Arquivo ZIP criado: #{@zip_path}")
    upload_zip
    @logger.info("Upload do arquivo ZIP concluído")
    update_video_status if @zip_uploaded
    @logger.info("Status do vídeo atualizado para 'processado'")
  ensure
    cleanup_temp_files
    @logger.info("Arquivos temporários limpos")
  end

  private

  def download_video
    @local_video_path = File.join(Dir.tmpdir, File.basename(@video.remote_path))
    File.open(@local_video_path, 'wb') do |file|
      @s3_client.get_object(bucket: @bucket_name, key: s3_key(@video.remote_path)) do |chunk|
        file.write(chunk)
      end
    end
  end

  def extract_frames
    @frames_dir = File.join(Dir.tmpdir, "frames_#{SecureRandom.uuid}")
    FileUtils.mkdir_p(@frames_dir)
    
    frame_rate = extract_frame_rate_from_metadata
    output_path = File.join(@frames_dir, 'frame_%04d.jpg')
    
    @logger.info("Iniciando extração de frames para: #{output_path}")
    
    # Usando o comando FFmpeg diretamente devido a incompatibilidades com a gem 'streamio-ffmpeg'
    command = [
      "ffmpeg", 
      "-i", @local_video_path, 
      "-vf", "fps=#{frame_rate}", 
      "-f", "image2", 
      "-pix_fmt", "yuvj420p", 
      "-q:v", "2", # Qualidade da imagem (2 é alta qualidade)
      output_path
    ]
    
    @logger.info("Executando comando: #{command.join(' ')}")
    
    output = `#{command.join(' ')} 2>&1`
    status = $?.success?
    
    unless status
      @logger.error("Falha na extração de frames: #{output}")
      raise "Falha na extração de frames. Saída do comando: #{output}"
    end
    
    frames = Dir.glob(File.join(@frames_dir, '*.jpg'))
    if frames.empty?
      @logger.error("Nenhum frame foi gerado em #{@frames_dir}")
      raise "Nenhum frame foi gerado em #{@frames_dir}"
    else
      @logger.info("#{frames.size} frames gerados com sucesso em #{@frames_dir}")
    end
  end

  def extract_frame_rate_from_metadata
    video_stream = @video.metadados['video_stream']
    match = video_stream.match(/(\d+)\s*fps/)
    match ? match[1].to_i : 30
  end

  def extract_pix_fmt_from_metadata
    video_stream = @video.metadados['video_stream']
    match = video_stream.split(',')[1]&.strip
    match || 'yuv420p' # Default to 'yuv420p' if not found
  end

  def create_zip
    @zip_path = File.join(Dir.tmpdir, "#{File.basename(@local_video_path, '.mp4')}.zip")
    
    frames = Dir.glob(File.join(@frames_dir, '*.jpg'))
    raise "No frames found in #{@frames_dir}" if frames.empty?
  
    Zip::File.open(@zip_path, Zip::File::CREATE) do |zipfile|
      frames.each do |frame|
        zipfile.add(File.basename(frame), frame)
      end
    end
    
    raise "Failed to create ZIP file at #{@zip_path}" unless File.exist?(@zip_path)
  end

  def upload_zip
    zip_key = s3_key(@video.remote_path).sub('.mp4', '.zip')
    @s3_client.put_object(
      bucket: @bucket_name,
      key: zip_key,
      body: File.open(@zip_path)
    )
    @video.update!(zip_images: "https://#{@bucket_name}.s3.amazonaws.com/#{zip_key}")
    @zip_uploaded = true
  rescue => e
    @zip_uploaded = false
    raise e
  end

  def update_video_status
    @video.update!(status: 'processado')
  end

  def cleanup_temp_files
    File.delete(@local_video_path) if @local_video_path && File.exist?(@local_video_path)
    FileUtils.rm_rf(@frames_dir) if @frames_dir && Dir.exist?(@frames_dir)
    File.delete(@zip_path) if @zip_path && File.exist?(@zip_path)
  end

  def s3_key(remote_path)
    URI.parse(remote_path).path[1..] # Remove leading slash
  end
end
