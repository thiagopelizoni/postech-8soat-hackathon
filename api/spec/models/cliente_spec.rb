require 'rails_helper'

RSpec.describe Cliente, type: :model do
  subject { build(:cliente) }

  describe 'validações' do
    it { is_expected.to validate_presence_of(:nome) }
    it { is_expected.to validate_presence_of(:data_nascimento) }
    it { is_expected.to validate_presence_of(:cpf) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:cpf) }
  end

  describe 'validação de CPF' do
    context 'quando o CPF é válido' do
      it 'permite salvar o cliente' do
        expect(subject).to be_valid
      end
    end

    context 'quando o CPF tem menos de 11 dígitos' do
      it 'não permite salvar' do
        subject.cpf = '123456789'
        expect(subject).not_to be_valid
        expect(subject.errors[:cpf]).to include('inválido')
      end
    end

    context 'quando o CPF tem todos os dígitos iguais' do
      it 'não permite salvar' do
        subject.cpf = '11111111111'
        expect(subject).not_to be_valid
        expect(subject.errors[:cpf]).to include('inválido')
      end
    end

    context 'quando o CPF tem dígitos inválidos' do
      it 'não permite salvar' do
        subject.cpf = '12345678900'
        expect(subject).not_to be_valid
        expect(subject.errors[:cpf]).to include('inválido')
      end
    end
  end
end
