class VideosController < ApplicationController
  include Authenticatable

  before_action :authenticate_cliente, only: [:index, :show, :create]
  before_action :set_video, only: %i[show]

  def index
    videos = Video.where(cliente: @cliente)
    render json: videos, status: :ok
  end

  def show
    if @video.cliente == @cliente
      render json: @video, status: :ok
    else
      render json: { error: 'Acesso não autorizado ao vídeo' }, status: :forbidden
    end
  end

  def create
    return render json: { error: "Arquivo de vídeo é obrigatório" }, status: :bad_request unless params[:arquivo]

    arquivo = params[:arquivo]
    extensao_arquivo = File.extname(arquivo.original_filename)

    unless extensao_arquivo.downcase == '.mp4'
      return render json: { error: "Apenas arquivos do tipo MP4 são permitidos" }, status: :unprocessable_entity
    end

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

  private

  def set_video
    @video = Video.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Vídeo não encontrado' }, status: :not_found
  end

  def video_params
    params.require(:video).permit(:nome)
  end
end
