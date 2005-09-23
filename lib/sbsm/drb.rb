#!/usr/bin/env ruby
# DRb::DRbObject -- fix bug in ruby -- 23.09.2005 -- hwyss@ywesee.com

require 'drb'

module DRb
	class DRbObject
		def respond_to?(msg_id)
			case msg_id
			when :_dump
				true
			when :marshal_dump
				false
			else
				method_missing(:respond_to?, msg_id)
			end
		end
	end
end
