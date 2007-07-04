# DistributedAssets
require 'zlib'

module Scoop
  module DistributedAssets # :nodoc:
    module AssetTagHelper

      def self.included(base)
        base.module_eval do
          # from rails edge rev 6354
          def rewrite_asset_path!(source)
            asset_id = rails_asset_id(source)
            source << "?#{asset_id}" if !asset_id.blank?
          end

          # from rails edge rev 6354
          def compute_asset_host(source)
            idx = (Zlib.crc32(source || "error" ) % ActionController::Base.asset_hosts.size)
            source = ActionController::Base.asset_hosts[idx] + source
          end
        end
        base.send :alias_method_chain, :compute_public_path, :random_asset_host
      end

      # from rails edge rev 6354
      def compute_public_path_with_random_asset_host(source, dir, ext, include_host = true)
        include_host = false if ActionController::Base.asset_hosts.size == 0
        source += ".#{ext}" if File.extname(source).blank?
      
        if source =~ %r{^[-a-z]+://}
          source
        else
          source = "/#{dir}/#{source}" unless source[0] == ?/
          source = "#{@controller.request.relative_url_root}#{source}"
          rewrite_asset_path!(source)

          if include_host
            host = compute_asset_host(source)
      
            unless host.blank? or host =~ %r{^[-a-z]+://}
              host = "#{@controller.request.protocol}#{host}"
            end
      
            "#{host}#{source}"
          else
            source
          end
        end
      end

    end
    
    module ActionControllerExtension
      def self.included(base)
        base.class_eval <<-EOF
          @@asset_hosts = []
          cattr_accessor :asset_hosts        
        EOF
        
        if base.asset_host.is_a?(Array)
          base.asset_hosts = base.asset_host
          base.asset_host = ""
        end
      end
    end
      
  end
end