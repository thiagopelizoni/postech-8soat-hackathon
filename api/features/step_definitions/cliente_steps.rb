require 'cucumber/rails'
require 'date'

Before do
  @attributes = {}
  @cliente = nil
end

Given(/^a valid cliente attributes:$/) do |table|
  @attributes = table.hashes.first
  @attributes['data_nascimento'] = Date.parse(@attributes['data_nascimento']) if @attributes['data_nascimento']
end

Given(/^I remove the "([^"]*)" attribute$/) do |attr|
  @attributes.delete(attr)
end

Given(/^I modify the cpf to be invalid by altering the last digit$/) do
  # Altera o último dígito para forçar um CPF inválido
  cpf = @attributes['cpf']
  if cpf && cpf.size == 11
    new_digit = cpf[-1] == '9' ? '0' : (cpf[-1].to_i + 1).to_s
    @attributes['cpf'] = cpf[0...-1] + new_digit
  end
end

When(/^I create the cliente$/) do
  @cliente = Cliente.new(@attributes)
  @cliente.valid?
end

Then(/^the cliente should be valid$/) do
  expect(@cliente).to be_valid
end

Then(/^the cliente should be invalid$/) do
  expect(@cliente).not_to be_valid
end

Then(/^the error for "([^"]*)" should include "([^"]*)"$/) do |attribute, message|
  expect(@cliente.errors[attribute]).to include(message)
end
