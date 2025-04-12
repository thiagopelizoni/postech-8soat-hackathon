class Video
  include Mongoid::Document
  include Mongoid::Timestamps

  field :local_path, type: String
  field :remote_path, type: String
  field :status, type: String, default: "recebido"
  field :metadados, type: Hash
  field :zip_images, type: String

  belongs_to :cliente

  validates :status, inclusion: { in: %w[recebido armazenado processado finalizado] }

  before_destroy :delete_s3_files

  def self.recebidos
    where(status: 'recebido')
  end

  def self.armazenados
    where(status: 'armazenado')
  end

  def self.processados
    where(status: 'processado')
  end

  def self.finalizados
    where(status: 'finalizado')
  end

  private

  def delete_s3_files
    s3_client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
    bucket_name = ENV['AWS_S3_BUCKET']

    [remote_path, zip_images].each do |path|
      next unless path&.start_with?('https://')

      key = path.split('.amazonaws.com/').last
      s3_client.delete_object(bucket: bucket_name, key: key)
    end
  end
end