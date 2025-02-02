require 'rails_helper'

RSpec.describe "Pedidos API", type: :request do
  let!(:pedido_em_aberto)  { create(:pedido, pagamento: "em_aberto", status: nil) }
  let!(:pedido_confirmado) { create(:pedido, pagamento: "confirmado", status: "recebido") }
  let!(:pedido_recusado)   { create(:pedido, pagamento: "recusado", status: nil) }

  describe "GET /pedidos" do
    it "retorna todos os pedidos ordenados por updated_at decrescente" do
      p1 = create(:pedido, updated_at: 1.hour.ago)
      p2 = create(:pedido, updated_at: Time.now)
      p1.touch; p2.touch
      get "/pedidos", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      first_time = Time.parse(json.first["updated_at"]) rescue nil
      second_time = Time.parse(json.second["updated_at"]) rescue nil
      expect(first_time).not_to be_nil
      expect(second_time).not_to be_nil
      expect(first_time).to be >= second_time
    end
  end

  describe "GET /pedidos/:id" do
    it "retorna um pedido específico" do
      pedido = pedido_confirmado
      get "/pedidos/#{pedido.id}", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(pedido.id.to_s)
    end
    it "retorna 404 para pedido inexistente" do
      get "/pedidos/nonexistent", as: :json
      expect(response).to have_http_status(404)
    end
  end

  describe "POST /pedidos" do
    context "com parâmetros válidos" do
      let(:valid_params) do
        { "pedido" => { "cliente" => { "nome" => "Test", "email" => "test@example.com", "cpf" => "12345678901", "token" => "abc123" },
                        "produtos" => [{ "id" => 1, "slug" => "produto-1", "nome" => "Produto 1", "preco" => 10 }],
                        "observacao" => "Observação válida",
                        "pagamento" => "em_aberto" } }
      end
      it "cria um novo pedido" do
        expect { post "/pedidos", params: valid_params, as: :json }.to change(Pedido, :count).by(1)
        expect(response).to have_http_status(201)
        json = JSON.parse(response.body)
        expect(json["cliente"]["nome"]).to eq("Test")
      end
    end
    context "com parâmetros inválidos" do
      let(:invalid_params) do
        { "pedido" => { "cliente" => { "nome" => "Test", "email" => "test@example.com", "cpf" => "12345678901", "token" => "abc123" },
                        "produtos" => [{ "id" => 1, "slug" => "produto-1", "nome" => "Produto 1", "preco" => 10 }],
                        "observacao" => "Observação válida",
                        "pagamento" => "em_aberto",
                        "status" => "recebido" } }
      end
      it "retorna erros de validação" do
        post "/pedidos", params: invalid_params, as: :json
        expect(response).to have_http_status(422)
        json = JSON.parse(response.body)
        expect(json).to have_key("status")
      end
    end
  end

  describe "PUT /pedidos/:id" do
    context "com atualização válida" do
      let(:pedido) { create(:pedido, pagamento: "confirmado", status: "recebido") }
      let(:update_params) { { "pedido" => { "observacao" => "Obs Atualizada", "status" => "em_preparacao" } } }
      it "atualiza o pedido" do
        put "/pedidos/#{pedido.id}", params: update_params, as: :json
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)
        expect(json["observacao"]).to eq("Obs Atualizada")
        expect(json["status"]).to eq("em_preparacao")
      end
    end
    context "com tentativa inválida de alterar status" do
      let(:pedido) { create(:pedido, pagamento: "em_aberto", status: nil) }
      let(:update_params) { { "pedido" => { "status" => "pronto" } } }
      it "não atualiza e retorna erro" do
        put "/pedidos/#{pedido.id}", params: update_params, as: :json
        expect(response).to have_http_status(422)
        json = JSON.parse(response.body)
        expect(json["status"]).to include("Não se pode atribuir Status se o Pagamento estiver Em Aberto")
      end
    end
  end

  describe "DELETE /pedidos/:id" do
    it "finaliza o pedido" do
      pedido = create(:pedido, pagamento: "confirmado", status: "recebido")
      delete "/pedidos/#{pedido.id}", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("Pedido foi finalizado com sucesso.")
      pedido.reload
      expect(pedido.status).to eq("finalizado")
    end
  end

  describe "GET /pedidos/search" do
    before do
      @p1 = create(:pedido, cliente: { "nome" => "Alice", "email" => "alice@example.com", "cpf" => "11111111111", "token" => "token1" },
                   produtos: [{ "nome" => "Pizza", "preco" => 20 }], pagamento: "confirmado", status: "recebido")
      @p2 = create(:pedido, cliente: { "nome" => "Bob", "email" => "bob@example.com", "cpf" => "22222222222", "token" => "token2" },
                   produtos: [{ "nome" => "Hamburger", "preco" => 15 }], pagamento: "em_aberto", status: nil)
      @p3 = create(:pedido, cliente: nil, produtos: [{ "nome" => "Salada", "preco" => 10 }], pagamento: "recusado", status: nil)
    end
    it "retorna todos os pedidos sem filtros" do
      get "/pedidos/search", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.size).to be >= 3
    end
    it "filtra por email do cliente" do
      get "/pedidos/search", params: { email: "alice@example.com" }, as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["cliente"]["email"] == "alice@example.com" }).to be true
    end
    it "filtra por cpf do cliente" do
      get "/pedidos/search", params: { cpf: "22222222222" }, as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["cliente"]["cpf"] == "22222222222" }).to be true
    end
    it "filtra por nome do produto (case insensitive)" do
      get "/pedidos/search", params: { produto: "piz" }, as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.any? { |p| p["produtos"].any? { |prod| prod["nome"].downcase.include?("piz") } }).to be true
    end
    it "filtra por cliente nulo" do
      get "/pedidos/search", params: { cliente_nulo: "true" }, as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["cliente"].nil? }).to be true
    end
    it "filtra por status" do
      get "/pedidos/search", params: { status: "recebido" }, as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["status"] == "recebido" }).to be true
    end
    it "filtra por pagamento" do
      get "/pedidos/search", params: { pagamento: "em_aberto" }, as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["pagamento"] == "em_aberto" }).to be true
    end
  end

  describe "GET /pedidos/pagamento_confirmado" do
    before do
      @pc = create(:pedido, pagamento: "confirmado", status: "recebido")
      @other = create(:pedido, pagamento: "em_aberto", status: nil)
    end
    it "retorna pedidos com pagamento confirmado" do
      get "/pedidos/pagamento_confirmado", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["pagamento"] == "confirmado" }).to be true
    end
  end

  describe "GET /pedidos/pagamento_em_aberto" do
    before do
      @pe = create(:pedido, pagamento: "em_aberto", status: nil)
      @other = create(:pedido, pagamento: "confirmado", status: "recebido")
    end
    it "retorna pedidos com pagamento em_aberto" do
      get "/pedidos/pagamento_em_aberto", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["pagamento"] == "em_aberto" }).to be true
    end
  end

  describe "GET /pedidos/pagamento_recusado" do
    before do
      @pr = create(:pedido, pagamento: "recusado", status: nil)
      @other = create(:pedido, pagamento: "confirmado", status: "recebido")
    end
    it "retorna pedidos com pagamento recusado" do
      get "/pedidos/pagamento_recusado", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["pagamento"] == "recusado" }).to be true
    end
  end

  describe "GET /pedidos/em_preparacao" do
    before do
      @ep = create(:pedido, pagamento: "confirmado", status: "em_preparacao")
      @other = create(:pedido, pagamento: "confirmado", status: "recebido")
    end
    it "retorna pedidos com status em_preparacao" do
      get "/pedidos/em_preparacao", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["status"] == "em_preparacao" }).to be true
    end
  end

  describe "GET /pedidos/finalizados" do
    before do
      @f = create(:pedido, pagamento: "confirmado", status: "finalizado")
      @other = create(:pedido, pagamento: "confirmado", status: "recebido")
    end
    it "retorna pedidos com status finalizado" do
      get "/pedidos/finalizados", as: :json
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.all? { |p| p["status"] == "finalizado" }).to be true
    end
  end

  describe "PUT /pedidos/:id/preparar" do
    context "quando o pagamento está confirmado" do
      let(:pedido) { create(:pedido, pagamento: "confirmado", status: "recebido") }
      it "atualiza o status para em_preparacao" do
        put "/pedidos/#{pedido.id}/preparar", as: :json
        expect(response).to have_http_status(200)
        pedido.reload
        expect(pedido.status).to eq("em_preparacao")
      end
    end
    context "quando o pagamento NÃO está confirmado" do
      let(:pedido) { create(:pedido, pagamento: "em_aberto", status: nil) }
      it "retorna erro" do
        put "/pedidos/#{pedido.id}/preparar", as: :json
        expect(response).to have_http_status(422)
        json = JSON.parse(response.body)
        expect(json["status"]).to include("Não se pode atribuir Status se o Pagamento estiver Em Aberto")
      end
    end
  end

  describe "PUT /pedidos/:id/pronto" do
    context "quando o pagamento está confirmado" do
      let(:pedido) { create(:pedido, pagamento: "confirmado", status: "em_preparacao") }
      it "atualiza o status para pronto" do
        put "/pedidos/#{pedido.id}/pronto", as: :json
        expect(response).to have_http_status(200)
        pedido.reload
        expect(pedido.status).to eq("pronto")
      end
    end
    context "quando o pagamento NÃO está confirmado" do
      let(:pedido) { create(:pedido, pagamento: "em_aberto", status: nil) }
      it "retorna erro" do
        put "/pedidos/#{pedido.id}/pronto", as: :json
        expect(response).to have_http_status(422)
        json = JSON.parse(response.body)
        expect(json["status"]).to include("Não se pode atribuir Status se o Pagamento estiver Em Aberto")
      end
    end
  end

  describe "PUT /pedidos/:id/finalizar" do
    context "quando o pagamento está confirmado" do
      let(:pedido) { create(:pedido, pagamento: "confirmado", status: "pronto") }
      it "atualiza o status para finalizado" do
        put "/pedidos/#{pedido.id}/finalizar", as: :json
        expect(response).to have_http_status(200)
        pedido.reload
        expect(pedido.status).to eq("finalizado")
      end
    end
    context "quando o pagamento NÃO está confirmado" do
      let(:pedido) { create(:pedido, pagamento: "em_aberto", status: nil) }
      it "retorna erro" do
        put "/pedidos/#{pedido.id}/finalizar", as: :json
        expect(response).to have_http_status(422)
        json = JSON.parse(response.body)
        expect(json["status"]).to include("Não se pode atribuir Status se o Pagamento estiver Em Aberto")
      end
    end
  end

  describe "GET /pedidos/:id/qr_code" do
    let(:pedido) { create(:pedido, pagamento: "confirmado", status: "recebido") }
    context "quando a integração com Mercado Pago é bem-sucedida" do
      before do
        allow_any_instance_of(Pedido).to receive(:integracao_mercado_pago).and_return(status: 201, response: { "sandbox_init_point" => "http://example.com/qr_code" })
      end
      it "retorna o link para pagamento (QR code)" do
        get "/pedidos/#{pedido.id}/qr_code", as: :json
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)
        expect(json).to have_key("link_pagamento")
        expect(json["link_pagamento"]).to eq("http://example.com/qr_code")
        expect(json).to have_key("pedido")
      end
    end
    context "quando a integração com Mercado Pago falha" do
      before do
        allow_any_instance_of(Pedido).to receive(:integracao_mercado_pago).and_return(status: 400, response: { "message" => "Erro na criação da preferência" })
      end
      it "retorna mensagem de erro" do
        get "/pedidos/#{pedido.id}/qr_code", as: :json
        expect(response).to have_http_status(422)
        json = JSON.parse(response.body)
        expect(json).to have_key("error")
        expect(json["error"]).to include("Erro na criação da preferência")
      end
    end
  end
end
