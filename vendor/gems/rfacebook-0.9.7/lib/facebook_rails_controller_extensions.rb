# This file is deprecated, but remains here for backward compatibility
require "rfacebook_on_rails/controller_extensions"
module RFacebook
  module RailsControllerExtensions
    def self.included(base)
      RAILS_DEFAULT_LOGGER.info "** RFACEBOOK DEPRECATION NOTICE: direct use of RFacebook::RailsControllerExtensions (from facebook_rails_controller_extensions.rb) is deprecated, use the RFacebook on Rails plugin instead (http://rfacebook.rubyforge.org)"
      base.send(:include, RFacebook::Rails::ControllerExtensions)
    end
  end
end