require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "active_job/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Api
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = 'Brasilia'

    config.autoload_lib(ignore: %w(assets tasks))
    config.api_only = true
  end
end
