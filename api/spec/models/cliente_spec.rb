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

    it "não é válido sem data_nascimento" do
      subject.data_nascimento = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:data_nascimento]).to include("can't be blank")
    end

    it "não é válido sem cpf" do
      subject.cpf = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:cpf]).to include("can't be blank")
    end

    it "não é válido sem email" do
      subject.email = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include("can't be blank")
    end

    it "não é válido com um CPF inválido (todos dígitos iguais)" do
      subject.cpf = "11111111111"
      expect(subject).not_to be_valid
      expect(subject.errors[:cpf]).to include("inválido")
    end

    it "não é válido com um CPF com dígitos incorretos" do
      cpf_invalido = subject.cpf[0..9] + ((subject.cpf[-1].to_i + 1) % 10).to_s
      subject.cpf = cpf_invalido
      expect(subject).not_to be_valid
      expect(subject.errors[:cpf]).to include("inválido")
    end
  end
end
