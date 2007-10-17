# Copyright (c) 2007, Matt Pizzimenti (www.livelearncode.com)
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 
# Neither the name of the original author nor the names of contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require File.dirname(__FILE__) + "/test_helper"
require "test/unit"
require "rubygems"
require "mocha"

class ModelTest < Test::Unit::TestCase
    
  def test_acts_as_facebook_user_is_present
    assert @model.class.respond_to?(:acts_as_facebook_user)
  end
  
  def test_facebook_extensions_are_present
    assert @model.respond_to?(:facebook_api_key)
    assert @model.respond_to?(:facebook_api_secret)
    assert @model.respond_to?(:facebook_session)
    assert @model.respond_to?(:facebook_session=)
    
    RFacebook::Rails::ModelExtensions::ActsAsFacebookUser::FIELDS.each do |field|
      assert @model.respond_to?(field), "Any model that acts_as_facebook_user should respond to '#{field}'"
    end
    
    assert @model.class.respond_to?(:find_or_create_by_facebook_session)
  end
  
  def test_facebook_properties_dispatched_to_internal_session
    
    # allow session to be used
    @model.facebook_session.expects(:is_activated?).at_least_once.returns(true)
    @model.facebook_session.expects(:post_request).at_least_once.returns @dummy_users_getInfo_response
    
    # try a bunch of fields
    assert_equal "http://photos-055.facebook.com/ip007/profile3/1271/65/s8055_39735.jpg", @model.pic, "Pic URL should be consistent with the facebook.users.getInfo response XML"
    assert_equal "November 3", @model.birthday, "Birthday should be consistent with the facebook.users.getInfo response XML"
    assert_equal "The Brothers K, GEB, Ken Wilber, Zen and the Art, Fitzgerald, The Emporer's New Mind, The Wonderful Story of Henry Sugar", @model.books, "Books should be consistent with the facebook.users.getInfo response XML"
    assert_equal "Dave", @model.first_name, "First name should be consistent with the facebook.users.getInfo response XML"
  end
  
  
  def setup
    @model = DummyModel.allocate # TODO: how do we properly test model instances that don't have database backing?
    
    @dummy_users_getInfo_response = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <users_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <user>
          <uid>8055</uid>
          <about_me>This field perpetuates the glorification of the ego.  Also, it has a character limit.</about_me>
          <activities>Here: facebook, etc. There: Glee Club, a capella, teaching.</activities>
          <affiliations list="true">
            <affiliation>
              <nid>50453093</nid>
              <name>Facebook Developers</name>
              <type>work</type>
              <status/>
              <year/>
            </affiliation>
          </affiliations> 
          <birthday>November 3</birthday>
          <books>The Brothers K, GEB, Ken Wilber, Zen and the Art, Fitzgerald, The Emporer's New Mind, The Wonderful Story of Henry Sugar</books>
          <current_location>
            <city>Palo Alto</city>
            <state>CA</state>
            <country>United States</country>
            <zip>94303</zip>
          </current_location>
          <education_history list="true">
            <education_info>
              <name>Harvard</name>
              <year>2003</year>
              <concentrations list="true">
                <concentration>Applied Mathematics</concentration>
                <concentration>Computer Science</concentration>
              </concentrations>
            </education_info>
          </education_history>
          <first_name>Dave</first_name>
           <hometown_location>
             <city>York</city>
             <state>PA</state>
             <country>United States</country>
             <zip>0</zip>
           </hometown_location>
           <hs_info>
             <hs1_name>Central York High School</hs1_name>
             <hs2_name/>
             <grad_year>1999</grad_year>
             <hs1_id>21846</hs1_id>
             <hs2_id>0</hs2_id>
           </hs_info>
           <is_app_user>1</is_app_user>
           <has_added_app>1</has_added_app>
           <interests>coffee, computers, the funny, architecture, code breaking,snowboarding, philosophy, soccer, talking to strangers</interests>
           <last_name>Fetterman</last_name>
           <meeting_for list="true">
             <seeking>Friendship</seeking>
           </meeting_for>
           <meeting_sex list="true">
             <sex>female</sex>
           </meeting_sex>
           <movies>Tommy Boy, Billy Madison, Fight Club, Dirty Work, Meet the Parents, My Blue Heaven, Office Space </movies>
           <music>New Found Glory, Daft Punk, Weezer, The Crystal Method, Rage, the KLF, Green Day, Live, Coldplay, Panic at the Disco, Family Force 5</music>
           <name>Dave Fetterman</name>
           <notes_count>0</notes_count>
           <pic>http://photos-055.facebook.com/ip007/profile3/1271/65/s8055_39735.jpg</pic>
           <pic_big>http://photos-055.facebook.com/ip007/profile3/1271/65/n8055_39735.jpg</pic>
           <pic_small>http://photos-055.facebook.com/ip007/profile3/1271/65/t8055_39735.jpg</pic>
           <pic_square>http://photos-055.facebook.com/ip007/profile3/1271/65/q8055_39735.jpg</pic>
           <political>Moderate</political>
           <profile_update_time>1170414620</profile_update_time>
           <quotes/>
           <relationship_status>In a Relationship</relationship_status>
           <religion/>
           <sex>male</sex>
           <significant_other_id xsi:nil="true"/>
           <status>
             <message/>
             <time>0</time>
           </status>
           <timezone>-8</timezone>
           <tv>cf. Bob Trahan</tv>
           <wall_count>121</wall_count>
           <work_history list="true">
             <work_info>
               <location>
                 <city>Palo Alto</city>
                 <state>CA</state>
                 <country>United States</country>
               </location>
               <company_name>Facebook</company_name>
               <position>Software Engineer</position>
               <description>Tech Lead, Facebook Platform</description>
               <start_date>2006-01</start_date>
               <end_date/>
              </work_info>
           </work_history>
         </user>
      </users_getInfo_response>
    EOF
  end
    
end

