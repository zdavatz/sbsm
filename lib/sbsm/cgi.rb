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
# CGI redefinitions

require 'cgi'
require 'drb/drb'

class CGI
	class Session
		attr_reader :output_cookies
	end
  def CGI::pretty(string, shift = "  ")
    lines = string.gsub(/(?!\A)<(?!\/(pre|textarea))(?:.)*?>/ni, "\n\\0").gsub(/<(?!(pre|textarea))(?:.)*?>(?!\n)/ni, "\\0\n")
	  end_pos = 0
		preformatted = []
		while end_pos = lines.index(/<\/pre/ni, end_pos)
			start_pos = lines.rindex(/<pre(\s+[^>]+)?>/ni, end_pos)
			start_pos += $~[0].length
			preformatted.push(lines[ start_pos ... end_pos ])
			lines[ start_pos ... end_pos ] = ''
			end_pos	= start_pos + 6
		end
    end_pos = 0
    while end_pos = lines.index(/^<\/(\w+)/n, end_pos)
      element = $1.dup
      start_pos = lines.rindex(/^\s*<#{element}/ni, end_pos)
      lines[start_pos ... end_pos] = "__" + lines[start_pos ... end_pos].gsub(/\n(?!\z)/n, "\n" + shift) + "__"
    end
    pretty = lines.gsub(/^((?:#{Regexp::quote(shift)})*)__(?=<\/?\w)/n, '\1')
		pos = 0
		preformatted.each { |pre|
			if(pos = pretty.index(/<\/pre/ni, pos))
				pretty[pos,0] = pre
				pos += pre.length + 6
			end
		}
		pretty
  end
	def CGI::escapeHTML(string)
		string.to_s.gsub(/&(?![^;]{2,6};)/n, '&amp;').gsub(/\"/n, '&quot;').gsub(/>/n, '&gt;').gsub(/</n, '&lt;')
	end
end
