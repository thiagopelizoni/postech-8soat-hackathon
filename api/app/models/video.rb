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

  def self.recebido
    where(status: 'recebido')
  end

  def self.armazenado
    where(status: 'armazenado')
  end

  def self.processado
    where(status: 'processado')
  end

  def self.finalizado
    where(status: 'finalizado')
  end
end