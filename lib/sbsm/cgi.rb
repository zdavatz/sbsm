#!/usr/bin/env ruby
# encoding: utf-8
#
# State Based Session Management
# Copyright (C) 2004 Hannes Wyss
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
# ywesee - intellectual capital connected, Winterthurerstrasse 52, CH-8006 Zürich, Switzerland
# hwyss@ywesee.com
#
# CGI redefinitions

require 'cgi'
require 'drb/drb'

class CGI
	module TagMaker
    def nOE_element_def(element, append = nil)
      s = <<-END
          "<#{element.upcase}" + attributes.collect{|name, value|
            next unless value
            " " + name.to_s +
            if true == value
              ""
            else
              '="' + CGI::escapeHTML(value) + '"'
            end
          }.to_s + ">"
      END
      s.sub!(/\Z/, " +") << append if append
      s
    end
	end
	class Session
		attr_reader :output_cookies
	end
  def CGI::pretty(string, shift = "  ")
    lines = string.gsub(/(?!\A)<(?!\/(pre|textarea))(?:.)*?>/ni, "\n\\0").gsub(/<(?!(pre|textarea))(?:.)*?>(?!\n)/i, "\\0\n")
	  end_pos = 0
		preformatted = []
		while (end_pos = lines.index(/<\/pre\s*>/i, end_pos)) \
      && (start_pos = lines.rindex(/<pre(\s+[^>]+)?>/i, end_pos))
			start_pos += $~[0].length
			preformatted.push(lines[ start_pos ... end_pos ])
			lines[ start_pos ... end_pos ] = ''
			end_pos	= start_pos + 6
		end
    end_pos = 0
    while end_pos = lines.index(/^<\/(\w+)/, end_pos)
      element = $1.dup
      start_pos = lines.rindex(/^\s*<#{element}/i, end_pos)
      lines[start_pos ... end_pos] = "__" + lines[start_pos ... end_pos].gsub(/\n(?!\z)/, "\n" + shift) + "__"
    end
    pretty = lines.gsub(/^((?:#{Regexp::quote(shift)})*)__(?=<\/?\w)/, '\1')
		pos = 0
		preformatted.each { |pre|
			if(pos = pretty.index(/<\/pre\s*>/i, pos))
				pretty[pos,0] = pre
				pos += pre.length + 6
			end
		}
		pretty
  end
	def CGI::escapeHTML(string)
    s = string.to_s.frozen? ? string.to_s : string.to_s.force_encoding('UTF-8')
		s.gsub(/&(?![^;]{2,6};)/, '&amp;').gsub(/\"/, '&quot;').gsub(/>/, '&gt;').gsub(/</, '&lt;')
	end
end
