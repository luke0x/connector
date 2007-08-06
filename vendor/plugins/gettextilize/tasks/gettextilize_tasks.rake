#
# Added for Ruby-GetText-Package
#

namespace :gettext do
  # Freeze to GetText 1.9.0 until we can review some parser problems 
  if Kernel.respond_to? :gem
    gem 'gettext', '= 1.9.0'
  else
    require_gem 'gettext', '= 1.9.0'
  end
  
  require 'gettext/utils'
  require 'gettext/rmsgmerge'
  
  desc "Create mo-files for L10n"
  task :makemo do
    GetText.create_mofiles(true, "po", "locale")
    Rake::Task['gettext:i18njs'].invoke
  end

  desc "Update pot/po files to match new version."
  task :updatepo do
    Rake::Task['gettext:getjs'].invoke
    
    to_parse = Dir.glob("{app/controllers,app/helpers,app/views,lib}/**/*.{rb,rhtml,rxml}")
        
    # Add the models which need localization here:
    to_parse.push('app/models/list.rb', 'app/models/list_folder_observer.rb', 'app/models/smart_group.rb')
    
    # note that if you don't want to localize column names you should add a call
    # to untranslate_all on the class definition.
    # See http://www.yotabanana.com/hiki/ruby-gettext-howto-rails.html for more info
    # regarding Rails specific adjustments.
    
    # Do not translate Model Class Names
    GetText::ActiveRecordParser.init(:use_classname => false)
    
    GetText.update_pofiles("connector",to_parse ,"Joyent Connector")
  	Rake::Task['gettext:cleanjs'].invoke
  end
  
  desc "Get localizable strings from JavaScript files"
  task :getjs do
    writejs(get_js_strings)
  end
  
  desc "Cleanup the temporary file created from js strings"
  task :cleanjs do
    puts "Cleaning up temporary JavaScript strings file\n"
    File.delete("#{RAILS_ROOT}/lib/js_strings.rb") if File.exists?("#{RAILS_ROOT}/lib/js_strings.rb")
  end
  
  desc "Create the JavaScript language files"
  task :i18njs do
    puts "Writing JavaScript language files\n"
    include GetText
    Locale.default = Locale::Object.new("en_GB.UTF-8")
    js_strings = get_js_strings

    locale_list = Dir.glob("#{RAILS_ROOT}/public/javascripts/lang/*.js")
    locale_list.each do |lc|
      code = File.basename(lc,'.js')
      template = "JoyentL10n = {\n"
      if code == 'en'
        template << js_strings.collect do |str|
          str + ':' + str
        end.join(",\n")
      else
        # non english, have to load from mo file
        Locale::set_current(code)
        bindtextdomain('connector',{:path => "#{RAILS_ROOT}/locale",:charset => 'UTF-8'})
        template << js_strings.collect do |str|
          localized = _(str[1,str.length-2])
          if localized.include?('"')
            localized = "'#{localized}'"
          elsif localized.include?('\'')
            localized = "'" << localized.gsub(/[']/, '\\\\\'') <<"'"
          else
            localized = "'" << localized <<"'"
          end
          str + ':' + localized
        end.join(",\n")
      end
      template << "\n}\n"
      File.open("#{RAILS_ROOT}/public/javascripts/lang/#{code}.js",'w') do |f|
        f.write(template)
      end
    end
  end
  
  desc "Get percentage localized for each translation"
  task :percentage do
    
    # This is the project file in original language:
    pot_file = parse_po(File.expand_path("#{RAILS_ROOT}/po/connector.pot"))
    project_messages = pot_file.msgids.size - 1 # first message on a po/pot file is always the header

    if /Project-Id-Version:(.*)/ =~ pot_file.instance_variable_get("@msgid2msgstr")['']
      project_name = $~[1].strip!
    else
      project_name = 'Joyent Connector'
    end
    
    po_files = Dir.glob("po/**/connector.po")
    
    unless po_files.nil? || po_files.empty?
      puts
      puts "Percentage localized for project <#{project_name}>:"
      puts "-"*10
      puts "Messages in project main file: #{project_messages}"
      puts "-"*10
      
      po_files.each do |pofile|
        puts "Localization: #{File.basename(File.dirname(pofile))}\n"
        parsed = parse_po(pofile)
        
        localized = parsed.instance_variable_get("@msgid2msgstr")
        # forget the header message
        localization_messages = parsed.msgids.size - 1
        localized.reject! { |k,v| k == ''}
        # count the localized ones
        localized.reject! { |k,v| v.empty?}
        localized_messages = localized.size
        puts "-"*10
        puts "Messages in localization: #{localization_messages}"
        puts "Messages localized: #{localized_messages}"
        puts "Percentage localized: #{(localized_messages*100)/project_messages}%"
        puts "-"*10
      end
    end
      
  end
  
  def writejs(js_strings)
    puts "Writting temporary .rb file to hold strings from JavaScript\n"
    File.open("#{RAILS_ROOT}/lib/js_strings.rb",'w') do |f|
      f.write(js_strings.collect{|str| '_(' << str << ")\n"})
    end
  end
  
  def get_js_strings()
    puts "Getting strings from JavaScript files"
    jsfiles = Dir.glob("#{RAILS_ROOT}/public/javascripts/*.js")
    js_strings = []
    jsfiles.each do |file|
      File.open(file,'r') do |f|
        while line = f.gets
          if line =~ /JoyentL10n\[(.*)\]/
            js_strings << $1
          end
        end
      end
    end
    js_strings.uniq.sort_by{|s| s.downcase}
  end
  
  private
  
  def parse_po(pofile)
    parser = GetText::PoParser.new
    # we're going to store raw data from file here
    str = nil
    # get the file from the given path
    # should do a bit of error checking here
    File.open(pofile){|f| str = f.read}
    # parse and return the contents
    postr = parser.parse(str, GetText::RMsgMerge::PoData.new, true)
  end
  
end
