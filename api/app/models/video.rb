class Video
  include Mongoid::Document
  include Mongoid::Timestamps

  field :local_path, type: String
  field :remote_path, type: String
  field :status, type: String, default: "recebido"
  field :metadados, type: Hash

  belongs_to :cliente

  validates :local_path, presence: true
  validates :status, inclusion: { in: %w[recebido armazenado processado finalizado] }

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
end