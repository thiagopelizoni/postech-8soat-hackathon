require 'faker'
require 'cpf_faker'

FactoryBot.define do
  factory :cliente do
    nome { Faker::Name.name }
    data_nascimento { Faker::Date.birthday(min_age: 18, max_age: 90) }
    cpf { Faker::CPF.numeric }
    email { Faker::Internet.email }
  end
end
