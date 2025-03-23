class Cliente
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nome, type: String
  field :email, type: String

  validates :nome, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
