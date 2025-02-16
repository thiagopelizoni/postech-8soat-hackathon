ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../../config/environment', __FILE__)
abort("O ambiente está em produção!") if Rails.env.production?

require 'cucumber/rails'
require 'httparty'
require 'json'
require 'rspec/expectations'

require 'webmock/cucumber'
WebMock.disable_net_connect!(allow_localhost: true)