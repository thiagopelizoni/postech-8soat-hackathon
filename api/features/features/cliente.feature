Feature: Validações do Modelo Cliente
  Como sistema
  Quero validar os dados de um cliente
  Para que apenas dados corretos sejam salvos

  Background:
    Given a valid cliente attributes:
      | nome           | data_nascimento | cpf         | email                     |
      | João da Silva  | 1990-01-01      | 52998224725 | joao.silva@example.com    |

  Scenario: Cliente é válido com todos os atributos obrigatórios
    When I create the cliente
    Then the cliente should be valid

  Scenario: Cliente não é válido sem nome
    Given a valid cliente attributes:
      | nome           | data_nascimento | cpf         | email                     |
      | João da Silva  | 1990-01-01      | 52998224725 | joao.silva@example.com    |
    And I remove the "nome" attribute
    When I create the cliente
    Then the cliente should be invalid
    And the error for "nome" should include "can't be blank"

  Scenario: Cliente não é válido sem data_nascimento
    Given a valid cliente attributes:
      | nome           | data_nascimento | cpf         | email                     |
      | João da Silva  | 1990-01-01      | 52998224725 | joao.silva@example.com    |
    And I remove the "data_nascimento" attribute
    When I create the cliente
    Then the cliente should be invalid
    And the error for "data_nascimento" should include "can't be blank"

  Scenario: Cliente não é válido sem cpf
    Given a valid cliente attributes:
      | nome           | data_nascimento | cpf         | email                     |
      | João da Silva  | 1990-01-01      | 52998224725 | joao.silva@example.com    |
    And I remove the "cpf" attribute
    When I create the cliente
    Then the cliente should be invalid
    And the error for "cpf" should include "can't be blank"

  Scenario: Cliente não é válido sem email
    Given a valid cliente attributes:
      | nome           | data_nascimento | cpf         | email                     |
      | João da Silva  | 1990-01-01      | 52998224725 | joao.silva@example.com    |
    And I remove the "email" attribute
    When I create the cliente
    Then the cliente should be invalid
    And the error for "email" should include "can't be blank"

  Scenario: Cliente não é válido com CPF contendo todos os dígitos iguais
    Given a valid cliente attributes:
      | nome           | data_nascimento | cpf         | email                     |
      | João da Silva  | 1990-01-01      | 11111111111 | joao.silva@example.com    |
    When I create the cliente
    Then the cliente should be invalid
    And the error for "cpf" should include "inválido"

  Scenario: Cliente não é válido com CPF com dígitos incorretos
    Given a valid cliente attributes:
      | nome           | data_nascimento | cpf         | email                     |
      | João da Silva  | 1990-01-01      | 52998224725 | joao.silva@example.com    |
    And I modify the cpf to be invalid by altering the last digit
    When I create the cliente
    Then the cliente should be invalid
    And the error for "cpf" should include "inválido"
