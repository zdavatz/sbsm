#!/usr/bin/env ruby
#
# State Based Session Management	
#	Copyright (C) 2004 Hannes Wyss
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#	ywesee - intellectual capital connected, Winterthurerstrasse 52, CH-8006 Zürich, Switzerland
#	hwyss@ywesee.com
#
# TestRequest -- sbsm -- 18.11.2002 -- hwyss@ywesee.com 

$: << File.dirname(__FILE__)
$: << File.expand_path("../lib", File.dirname(__FILE__))

require 'test/unit'
require 'stub/cgi'
require 'sbsm/request'

module Apache
	def request
	end
	module_function :request
end
class TestRequest < Test::Unit::TestCase
	def setup
		@request = SBSM::Request.new(nil)
	end
	def test_delegates
		cgi = @request.cgi
		exclude = %w{freeze pretty_print_inspect}
		cgi.public_methods.each { |method| 
			if(!exclude.include?(method) && cgi.method(method).arity==0)
				assert_nothing_raised {
					@request.send(method) unless(['type', 'to_a'].include?(method))
				}
			end
		}
	end
end
