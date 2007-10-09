=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class TestJajahSystem
  def call(from_user, from_number, to_numbers)
    if from_user.jajah_username == 'ian'
      return 1
    elsif from_user.jajah_username == 'badname'
      raise JajahError.new("Invalid username or password.", -1)
    else 
      return 1
    end
  end
  
  def get_numbers(jajah_username, jajah_password)
    {"landLine" => ["1231231234"], "mobile" => ["5555555555"]}
  end
  
  def get_balance(jajah_username, jajah_password)
    [119.123123232, "USD"]
  end
end