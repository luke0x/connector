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

require "hpricot"

module RFacebook

  module FacepricotChaining
  
    def make_facepricot_chain(key, doc)
    
      if matches = /(.*)_list/.match(key)
        listKey = matches[1]
      end
    
      result = nil
      
      if !result
        if listKey
          result = doc.search("/#{listKey}")
        end
      end
    
      if !result
        result = doc.at("/#{key}")
      end
    
      if !result
        if listKey
          result = doc.search("//#{listKey}")
        end
      end
    
      if !result
        result = doc.at("//#{key}")
      end
    
      if result
        if result.is_a?(Array)
          return result.map{|r| FacepricotChain.new(r)}
        else
          return FacepricotChain.new(result)
        end
      else
        return nil
      end
    
    end
    
  end
  
  class Facepricot
    
    include FacepricotChaining
    
    def initialize(xml)
      @doc = Hpricot.XML(xml)
      @raw_xml = xml
    end
    
    def method_missing(methodSymbol, *params)
      begin
        @doc.method(methodSymbol).call(*params) # pose as Hpricot document
      rescue
        return make_facepricot_chain(methodSymbol.to_s, @doc.containers[0])
      end
    end
    
    def hpricot
      return @doc
    end
    
    def response
      return FacepricotChain.new(@doc.containers[0])
    end
    
    def raw_xml
      return @raw_xml
    end
    
    def to_s
      return @doc.containers[0].inner_html
    end
    
    def get(key)
      return make_facepricot_chain(key.to_s, @doc.containers[0])
    end
        
  end
  
  class FacepricotChain < String

    include FacepricotChaining

    def initialize(hpricotDoc)
      super(hpricotDoc.inner_html.gsub("&amp;", "&"))
      @doc = hpricotDoc
    end
    
    def method_missing(methodSymbol, *params)
      return make_facepricot_chain(methodSymbol.to_s, @doc)
    end
    
    def get(key)
      return make_facepricot_chain(key.to_s, @doc)
    end
    
  end

  
end
