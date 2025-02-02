class Cliente
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nome, type: String
  field :data_nascimento, type: Date
  field :cpf, type: String
  field :email, type: String

  validates :nome, presence: true
  validates :data_nascimento, presence: true
  validates :cpf, presence: true, uniqueness: true
  validates :email, presence: true

  validate :cpf_valido?

  private

  def cpf_valido?
    return if cpf.blank?

    numbers = cpf.gsub(/\D/, '')

    return errors.add(:cpf, 'inválido') unless numbers.length == 11
    return errors.add(:cpf, 'inválido') if numbers.chars.uniq.size == 1

    errors.add(:cpf, 'inválido') unless cpf_valido_mod11?(numbers)
  end

  def cpf_valido_mod11?(numbers)
    first_digit = calcular_digito_verificador(numbers[0..8])
    second_digit = calcular_digito_verificador(numbers[0..9])
    numbers[-2..] == "#{first_digit}#{second_digit}"
  end

  def calcular_digito_verificador(digits)
    sum = digits.chars.each_with_index.sum { |digit, index| digit.to_i * (digits.length + 1 - index) }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
