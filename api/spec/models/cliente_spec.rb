require 'rails_helper'

RSpec.describe Cliente, type: :model do
  subject { build(:cliente) }

  describe "Validações" do
    it "é válido com todos os atributos obrigatórios" do
      expect(subject).to be_valid
    end

    it "não é válido sem nome" do
      subject.nome = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:nome]).to include("can't be blank")
    end

    it "não é válido sem email" do
      subject.email = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include("can't be blank")
    end

    context 'quando o email é inválido' do
      subject { Cliente.new(nome: 'Lindsay Hegmann', email: 'usuario') }
      it 'não é válido com um email inválido' do
        expect(subject).not_to be_valid
      end
    end

    # it "não é válido com um email inválido" do
    #   emails_invalidos = ["usuario", "usuario@", "usuario@com", "@dominio.com", "usuario@.com", "usuario@dominio,com"]
    #   emails_invalidos.each do |email_invalido|
    #     subject.email = email_invalido
    #     expect(subject).not_to be_valid
    #     expect(subject.errors[:email]).to include("is invalid")
    #   end
    # end
  end
end
