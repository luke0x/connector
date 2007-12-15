require "rubygems"

begin
  require "rfacebook_on_rails/plugin/install"
rescue Exception => e
  puts "There was a problem loading the RFacebook on Rails plugin.  You may have forgotten to install the RFacebook Gem."
  raise e
end
