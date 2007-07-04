#!/usr/bin/env ruby
#
#  Copyright (c) 2006-2007 Joyent Inc. 
#  Licensed under the same terms as Joyent Connector.

require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class GettextilizeDateHelperTest < Test::Unit::TestCase
  Locale.default = Locale::Object.new("en_GB.UTF-8")
  GetText.locale = "es"
    
  include ActionView::Helpers::DateHelper
  extend ActionView::Helpers::DateHelper
  def test_localize_distance_of_time_in_words
    assert_equal distance_of_time_in_words(90),"1 minuto"
    assert_equal distance_of_time_in_words(30),"menos de un minuto"
    assert_equal distance_of_time_in_words(3,0,true),"menos de 5 segundos"
    assert_equal distance_of_time_in_words(7,0,true),"menos de 10 segundos"
    assert_equal distance_of_time_in_words(13,0,true),"menos de 20 segundos"
    assert_equal distance_of_time_in_words(24,0,true),"medio minuto"
    assert_equal distance_of_time_in_words(44,0,true),"menos de un minuto"
    assert_equal distance_of_time_in_words(360),"6 minutos"
    assert_equal distance_of_time_in_words(3600),"sobre 1 hora"
    assert_equal distance_of_time_in_words(8600),"sobre 2 horas"
    assert_equal distance_of_time_in_words(86800),"1 día"
    assert_equal distance_of_time_in_words(259200),"3 días"
  end

end
