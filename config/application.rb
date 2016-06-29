require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

Bundler.require *Rails.groups

module HrPdf
  class Application < Rails::Application
    config.generators do |g|
      g.assets   = false
      g.helper   = false
      g.jbuilder = false
    end
  end
end
