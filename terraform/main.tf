provider "aws" {
  region = "us-east-1"
}

resource "aws_cognito_user_pool" "user_pool" {
  name = "SandboxUserPool"

  schema {
    name                = "cpf"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "nome"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "data_nascimento"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "SandboxUserPoolClient"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}
