#!/usr/bin/env ruby
# Redirector -- sbsm -- 02.11.2006 -- hwyss@ywesee.com

module SBSM
  module Redirector
    def http_headers
      if(redirect?) 
        @redirected = @state.redirected = true
        event, *args = @state.direct_event
        if(args.first.is_a? Hash)
          args = args.first
        end
        { 
          "Location" => lookandfeel._event_url(event, args || {}),
        }
      else
        super 
      end
    end
    def redirect?
      direct = @state.direct_event
      if(direct.is_a?(Array))
        direct = direct.first
      end
      direct && (@request_method != 'GET' \
                 || ![direct, :sort].include?(event))
    end
    def to_html
      if(redirect?)
        ''
      else
        super
      end
    end
  end
end
