require 'csv'

file_path = Rails.root.join('db', 'seeds', 'usuarios.csv')

CSV.foreach(file_path, headers: true) do |row|
  Cliente.create!(
    nome: row['nome'],
    data_nascimento: row['data_nascimento'],
    cpf: row['cpf'],
    email: row['email']
  )
end

puts "Clientes importados com sucesso!"