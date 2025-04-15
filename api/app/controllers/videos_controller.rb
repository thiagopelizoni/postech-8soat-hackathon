class VideosController < ApplicationController
  before_action :authenticate_cliente, only: [:create]
  before_action :set_video, only: %i[show update destroy]

  def index
    videos = Video.all
    render json: videos, status: :ok
  end

  def show
    render json: @video, status: :ok
  end

  def create
    return render json: { error: "Arquivo de vídeo é obrigatório" }, status: :bad_request unless params[:arquivo]
  
    arquivo = params[:arquivo]
    
    extensao_arquivo = File.extname(arquivo.original_filename)
    nome_arquivo = "#{SecureRandom.uuid}#{extensao_arquivo}"
    caminho_arquivo = Rails.root.join('tmp', nome_arquivo)
  
    File.open(caminho_arquivo, 'wb') do |file|
      file.write(arquivo.read)
    end
  
    metadados = FFMPEG::Movie.new(caminho_arquivo.to_s)
  
    video = Video.new(
      local_path: caminho_arquivo.to_s,
      metadados: {
        duration: metadados.duration,
        bitrate: metadados.bitrate,
        resolution: metadados.resolution,
        video_stream: metadados.video_stream,
        audio_stream: metadados.audio_stream
      },
      cliente: @cliente
    )
  
    if video.save
      VideoUploadJob.perform_later(video.id)
      render json: video, status: :created
    else
      render json: { errors: video.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @video.update(video_params)
      render json: @video, status: :ok
    else
      render json: { errors: @video.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    File.delete(@video.caminho_arquivo) if File.exist?(@video.caminho_arquivo)
    @video.destroy
    head :no_content
  end

  private

  def authenticate_cliente
    authorization_header = request.headers['Authorization']
    return render json: { error: 'Token de acesso é obrigatório' }, status: :unauthorized unless authorization_header

    token_type, access_token = authorization_header.split(' ')
    return render json: { error: 'Formato de token inválido' }, status: :unauthorized unless token_type == 'Bearer' && access_token.present?

    return render json: { error: 'Token inválido ou expirado' }, status: :unauthorized unless CognitoAuth.valid_token?(access_token)

    @cliente = Cliente.authenticate(access_token)
    return render json: { error: 'Cliente não encontrado' }, status: :not_found unless @cliente
  end

  def set_video
    @video = Video.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Vídeo não encontrado' }, status: :not_found
  end

  def video_params
    params.require(:video).permit(:nome)
  end
end
