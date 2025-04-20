class Cliente
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nome, type: String
  field :email, type: String
  field :token, type: String
  field :access_token, type: String
  field :refresh_token, type: String
  field :admin, type: Boolean, default: false
  
  validates :nome, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :videos

  def self.authenticate(access_token)
    Cliente.find_by(access_token: access_token)
  end

  def admin?
    self.admin
  end
end
