ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../../config/environment', __FILE__)
abort("O ambiente está em produção!") if Rails.env.production?

require 'cucumber/rails'
require 'httparty'
require 'json'
require 'rspec/expectations'

require 'webmock/cucumber'
WebMock.disable_net_connect!(allow_localhost: true)

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/features/'
end