=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'soap/wsdlDriver'

class ProductionJajahSystem
  cattr_accessor :jajah_affiliate_code, :jajah_call_service_wsdl_uri, :jajah_member_service_wsdl_uri
  @@jajah_affiliate_code          = '12345'
  @@jajah_call_service_wsdl_uri   = 'http://localhost'
  @@jajah_member_service_wsdl_uri = 'http://localhost'
  
  def initialize
    @logger = Logger.new("#{RAILS_ROOT}/log/jajah.log")
  end
  
  def call(from_user, from_number, to_numbers)
    @logger.info("Call being made by #{from_user.username} from #{from_number} to (#{to_numbers.join(', ')})")
    
    to_numbers = [to_numbers] unless to_numbers.kind_of?(Array)
    set_up_service(@@jajah_call_service_wsdl_uri) do |driver|
      parse_call_result(driver.InitCall1({"privateMode" => 'BothNumbersAreVisible', 
                                          "affiliateId" => @@jajah_affiliate_code,
                                          "userName"    => from_user.jajah_username, 
                                          "password"    => from_user.jajah_password, 
                                          "FromNumber"  => sanitize(from_number), 
                                          "ToNumbers"   => to_numbers.collect{|number| sanitize(number)}}))
    end
  end
  
  def get_numbers(jajah_username, jajah_password)
    @logger.info("Get numbers for #{jajah_username}")
    
    set_up_service(@@jajah_member_service_wsdl_uri) do |driver|
      parse_get_numbers_result(driver.GetMemberNumbers({"userName" => jajah_username, 
                                                        "password" => jajah_password}))
    end
  end
  
  def get_balance(jajah_username, jajah_password)
    @logger.info("Get balance for #{jajah_username}")
    
    set_up_service(@@jajah_member_service_wsdl_uri) do |driver|
      parse_get_balance_result(driver.GetMemberBalance({"userName" => jajah_username, 
                                                        "password" => jajah_password}))
    end
  end
  
  private
  
  def set_up_service(wsdl_uri, &block)
    yield SOAP::WSDLDriverFactory.new(wsdl_uri).create_rpc_driver
  rescue SocketError, SystemCallError, Timeout::Error
    raise JajahError.new("Unable to connect to Jajah.", -98)
  rescue => e
    if e.kind_of?(JajahError)
      @logger.info("Jajah Error #{e.message} (#{e.code})")
      raise
    end
    
    @logger.info("Unknown error in Jajah call (#{e.message}). \n#{e.backtrace.join("\n")}")
    raise JajahError.new("Unknown error.", -99)   
  end
  
  def sanitize(phone_number)
    phone_number && phone_number.gsub(/[^0-9]/, '')
  end
  
  def parse_call_result(result)
    verify_successful(result, true)
  end
  
  def parse_get_numbers_result(result)
    verify_successful(result)
    
    phone_numbers = {}
    (1...result.__xmlele.size).each do |index|
      type   = result.__xmlele[index][0].name
      number = result.__xmlele[index][1]
      next unless number.kind_of?(String)
      
      phone_numbers[type] ||= []
      phone_numbers[type] << number
    end
      
    phone_numbers
  end
  
  def parse_get_balance_result(result)
    verify_successful(result)
    
    amount = result.__xmlele[1][1].to_f
    type   = currency_lookup(result.__xmlele[2][1])

    [amount, type]
  end
  
  def verify_successful(result, call=false)
    result_code = result.__xmlele[0][1].to_i
    
    return result_code if result_code > 0
    
    error = case result_code
    when  -1 then "Invalid username or password."
    when  -2 then "Username or password are empty."
    when  -3 then "Invalid country code."
    when  -4 then call ? "No 'from' number set." : "Internal Jajah error."
    when  -5 then "No 'to' number(s) set."      
    when  -6 then "Invalid 'to' number(s)."
    when  -7 then "Internal Jajah error."
    when  -8 then "Connection is not secured."
    when  -9 then "Jajah user's credit is too low."
    else          "Unknown Jajah error code (#{result_code})."
    end
    
    raise JajahError.new(error, result_code)
  end
    
  def currency_lookup(code)
    {'1' => 'EUR', '2' => 'USD', '3' => 'JPY', '4' => 'GBP', '5' => 'CNY'}[code.to_s]
  end
end