class ClienteSerializer < ActiveModel::Serializer
  attributes :id, :nome, :email, :token, :access_token, :refresh_token
end