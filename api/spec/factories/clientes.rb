require 'faker'

FactoryBot.define do
  factory :cliente do
    nome { Faker::Name.name }
    email { Faker::Internet.email }
  end
end
