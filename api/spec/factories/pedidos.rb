require 'faker'

FactoryBot.define do
  factory :pedido do
    cliente do
      {
        nome: Faker::Name.name,
        email: Faker::Internet.email,
        cpf: Faker::Number.number(digits: 11),
        token: Faker::Alphanumeric.alphanumeric(number: 10)
      }
    end

    produtos do
      Array.new(3) do
        {
          id: Faker::Number.unique.between(from: 1, to: 1000),
          slug: Faker::Food.dish.parameterize,
          nome: Faker::Food.dish,
          preco: Faker::Number.between(from: 5, to: 50)
        }
      end
    end

    observacao { Faker::Lorem.sentence(word_count: 10) }
    valor { produtos.present? ? produtos.compact.sum { |p| p[:preco].to_f } : 0.0 }
    pagamento { %w[em_aberto confirmado recusado].sample }
    status { pagamento == 'confirmado' ? %w[recebido em_preparacao pronto finalizado].sample : nil }
  end
end
