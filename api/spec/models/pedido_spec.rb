require 'rails_helper'

RSpec.describe Pedido, type: :model do
  describe 'validations' do
    subject { build(:pedido) }

    context 'pagamento' do
      it 'is valid with allowed values' do
        Pedido::PAGAMENTOS.each do |p|
          subject.pagamento = p
          subject.status = p == 'confirmado' ? Pedido::STATUS.first : nil
          expect(subject).to be_valid
        end
      end

      it 'is invalid with an unknown value' do
        subject.pagamento = 'invalid'
        expect(subject).not_to be_valid
        expect(subject.errors[:pagamento]).to include("is not included in the list")
      end
    end

    context 'status for confirmed pagamento' do
      before { subject.pagamento = 'confirmado' }

      it 'is invalid when blank' do
        subject.status = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:status]).to include('Status é obrigatório quando o Pagamento já tiver sido confirmado')
      end

      it 'is invalid when not in list' do
        subject.status = 'invalid'
        expect(subject).not_to be_valid
        expect(subject.errors[:status]).to include("is not included in the list")
      end

      it 'is valid when in allowed list' do
        subject.status = Pedido::STATUS.first
        expect(subject).to be_valid
      end
    end

    context 'status for em_aberto and recusado' do
      it 'is invalid when status is provided for em_aberto' do
        subject.pagamento = 'em_aberto'
        subject.status = Pedido::STATUS.first
        expect(subject).not_to be_valid
        expect(subject.errors[:status]).to include('Não se pode atribuir Status se o Pagamento estiver Em Aberto')
      end

      it 'is valid when status is blank for em_aberto' do
        subject.pagamento = 'em_aberto'
        subject.status = nil
        expect(subject).to be_valid
      end

      it 'is invalid when status is provided for recusado' do
        subject.pagamento = 'recusado'
        subject.status = Pedido::STATUS.first
        expect(subject).not_to be_valid
        expect(subject.errors[:status]).to include('Não se pode atribuir Status se o Pagamento estiver Em Aberto')
      end

      it 'is valid when status is blank for recusado' do
        subject.pagamento = 'recusado'
        subject.status = nil
        expect(subject).to be_valid
      end
    end

    context 'produtos' do
      it 'is invalid when produtos is empty' do
        subject.produtos = []
        expect(subject).not_to be_valid
        expect(subject.errors[:produtos]).to include("can't be blank")
      end

      it 'is valid when produtos is present' do
        subject.produtos = [{ 'nome' => 'Prod1', 'preco' => 10 }]
        expect(subject).to be_valid
      end
    end

    context 'observacao' do
      it 'is invalid when longer than 500 characters' do
        subject.observacao = 'a' * 501
        expect(subject).not_to be_valid
        expect(subject.errors[:observacao]).to include("is too long (maximum is 500 characters)")
      end

      it 'is valid when 500 characters or less' do
        subject.observacao = 'a' * 500
        expect(subject).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe '#calculate_valor' do
      it 'sets valor as the sum of produtos preços' do
        produtos = [
          { 'nome' => 'Prod1', 'preco' => 10 },
          { 'nome' => 'Prod2', 'preco' => 20 },
          { 'nome' => 'Prod3', 'preco' => 30 }
        ]
        pedido = build(:pedido, produtos: produtos)
        pedido.save
        expect(pedido.valor).to eq(60)
      end

      it 'sets valor as 0.0 if produtos is empty' do
        pedido = build(:pedido, produtos: [])
        pedido.save(validate: false)
        expect(pedido.valor).to eq(0.0)
      end
    end

    describe '#validate_status_change' do
      context 'when updating status with pagamento not confirmed' do
        it 'prevents update and adds error' do
          pedido = create(:pedido, pagamento: 'em_aberto', status: nil, produtos: [{ 'nome' => 'Prod', 'preco' => 10 }])
          pedido.status = 'pronto'
          result = pedido.save
          expect(result).to be false
          expect(pedido.errors[:status]).to include('Não se pode atribuir Status se o Pagamento estiver Em Aberto')
        end
      end

      context 'when updating status with pagamento confirmed' do
        it 'allows update' do
          pedido = create(:pedido, pagamento: 'confirmado', status: 'recebido', produtos: [{ 'nome' => 'Prod', 'preco' => 10 }])
          pedido.status = 'pronto'
          expect(pedido.save).to be true
          expect(pedido.reload.status).to eq('pronto')
        end
      end
    end
  end

  describe '#integracao_mercado_pago' do
    it 'calls Mercadopago SDK with correct parameters and returns response' do
      pedido = create(:pedido, cliente: { 'nome' => 'John Doe', 'email' => 'john@example.com' }, produtos: [{ 'nome' => 'Produto 1', 'preco' => 10 }, { 'nome' => 'Produto 2', 'preco' => 20 }], pagamento: 'confirmado', status: 'recebido')
      expected_items = pedido.produtos.map do |produto|
        { title: produto['nome'], quantity: 1, unit_price: produto['preco'].to_f }
      end
      expected_data = {
        items: expected_items,
        payer: { name: pedido.cliente['nome'], email: pedido.cliente['email'] },
        external_reference: pedido.id.to_s,
        notification_url: ENV['MERCADO_PAGO_WEBHOOK_URL'],
        payment_methods: { excluded_payment_types: [{ id: 'ticket' }] }
      }
      sdk_double = instance_double("Mercadopago::SDK")
      preference_double = instance_double("Mercadopago::Preference")
      response_stub = { status: 201, response: { 'sandbox_init_point' => 'http://example.com/qr_code' } }
      expect(Mercadopago::SDK).to receive(:new).with(ENV['MERCADO_PAGO_ACCESS_TOKEN']).and_return(sdk_double)
      expect(sdk_double).to receive(:preference).and_return(preference_double)
      expect(preference_double).to receive(:create).with(expected_data).and_return(response_stub)
      result = pedido.integracao_mercado_pago
      expect(result).to eq(response_stub)
    end
  end
end
