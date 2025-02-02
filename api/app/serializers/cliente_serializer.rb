class ClienteSerializer < ActiveModel::Serializer
  attributes :id, :nome, :email, :cpf, :data_nascimento

  def data_nascimento
    object.data_nascimento.strftime("%d/%m/%Y")
  end
end