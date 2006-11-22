#!/usr/bin/env ruby
# Redirector -- sbsm -- 02.11.2006 -- hwyss@ywesee.com

module SBSM
  module Redirector
    def http_headers
      if(redirect?) 
        event, args = @state.direct_event
        { 
          "Location" => lookandfeel._event_url(event, args || {}),
        }
      else
        super 
      end
    end
    def redirect?
      @state.direct_event && @request_method != 'GET'
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
