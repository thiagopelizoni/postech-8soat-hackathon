class ClienteSerializer < ActiveModel::Serializer
  attributes :id, :nome, :email, :cpf, :data_nascimento, :observacao, :data, :data_status, :pagamento

  def data_nascimento
    object.data_nascimento.strftime("%d/%m/%Y")
  end
end