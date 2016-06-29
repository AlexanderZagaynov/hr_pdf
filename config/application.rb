require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

Bundler.require *Rails.groups

module HrPdf
  class Application < Rails::Application
  end
end
