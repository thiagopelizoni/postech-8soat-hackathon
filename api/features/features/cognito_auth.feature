Feature: Serviço CognitoAuth
  Para gerenciar usuários via AWS Cognito
  Como a aplicação
  Quero poder registrar, autenticar, atualizar e deletar usuários

  Background:
    Given the AWS region is set to "us-east-1"
    And the COGNITO_USER_POOL_ID is set to "pool123"
    And the COGNITO_USER_POOL_CLIENT_ID is set to "client123"

  Scenario: Registro de usuário com sucesso
    When I register a user with email "user@example.com", password "Password1!", and cpf "12345678901"
    Then the registration result should be true

  Scenario: Falha no registro devido a erro da AWS
    Given Cognito register will fail with error "Registration failed"
    When I register a user with email "user@example.com", password "Password1!", and cpf "12345678901"
    Then the registration result should be an error with message "Registration failed"

  Scenario: Autenticação de usuário com sucesso
    Given Cognito authenticate will return tokens:
      | id_token      | id-token-sample      |
      | access_token  | access-token-sample  |
      | refresh_token | refresh-token-sample |
    When I authenticate with email "user@example.com" and password "Password1!"
    Then the authentication result should include token "id-token-sample" for "id_token"
    And the authentication result should include token "access-token-sample" for "access_token"
    And the authentication result should include token "refresh-token-sample" for "refresh_token"

  Scenario: Falha na autenticação por credenciais inválidas
    Given Cognito authenticate will fail
    When I authenticate with email "user@example.com" and password "WrongPassword!"
    Then the authentication result should be nil

  Scenario: Deleção de usuário com sucesso
    Given Cognito delete user will succeed
    When I delete user with cpf "12345678901"
    Then no error should be raised

  Scenario: Atualização de usuário com sucesso (novo email e nova senha)
    Given Cognito update user will succeed
    When I update user with cpf "12345678901", new email "new@example.com" and new password "NewPassword1!"
    Then the update result should be true

  Scenario: Falha na atualização do usuário devido a erro da AWS
    Given Cognito update user will fail with error "Update failed"
    When I update user with cpf "12345678901", new email "new@example.com" and new password "NewPassword1!"
    Then the update result should be an error with message "Update failed"
