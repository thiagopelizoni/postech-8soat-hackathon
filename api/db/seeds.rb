require 'faker'

clientes = []

200.times do
  clientes << {
    nome: Faker::Name.name,
    data_nascimento: Faker::Date.birthday(min_age: 18, max_age: 90),
    cpf: Faker::CPF.numeric,
    email: Faker::Internet.email
  }
end

Cliente.create!(clientes)

puts "Clientes gerados com sucesso!"
