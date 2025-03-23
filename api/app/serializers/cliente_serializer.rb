class ClienteSerializer < ActiveModel::Serializer
  attributes :id, :nome, :email
end