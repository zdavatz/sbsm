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
# Lookandfeel -- sbsm -- hwyss@ywesee.com

require 'sbsm/time'

module SBSM
  class Lookandfeel
    attr_reader :language, :flavor
    protected
    attr_reader :session
    public
    DICTIONARIES = {}
		ENABLED = []
		HTML_ATTRIBUTES = {}
		RESOURCES = {}
		RESOURCE_BASE = "/resources"
		TXT_RESOURCES = "/resources"
		class << self
			def txt_file(filename)
				Proc.new {
					path = File.expand_path(filename, self::TXT_RESOURCES)
					File.read(path).strip.gsub(/(\r\n)|(\n)|(\r)/, '<br>')
				}
			end
		end
		def initialize(session)
      @session = session
      @flavor = @session.flavor
      @language = @session.language
      set_dictionary(@language)
			#set_resources_language(@language)
		end
		def attributes(key)
			self::class::HTML_ATTRIBUTES.fetch(key, {}).dup
		end
    def base_url
      [@session.http_protocol + ':/', @session.server_name, @language, @flavor].compact.join("/")
    end
		def direct_event
			@session.direct_event
		end
		def enabled?(event, default=true)
			default || self::class::ENABLED.include?(event)
		end
		def event_url(event=direct_event, args={})
			unless(args.respond_to?(:include?) && args.include?('state_id'))
				args = args.to_a
				args.unshift(["state_id", @session.state.id])
			end
			[base_url(), event, args.flatten].compact.join('/')
		end
		def languages
			@languages ||= self::class::DICTIONARIES.keys.sort
		end
		def language_url(language)
			[@session.http_protocol + ':/', @session.server_name, language, @flavor].compact.join("/")
		end
		def lookup(key, *args)
			key = key.intern if key.is_a? String
			if(args.size > 0)
				result = ""
				args.each_with_index { |text, index|
					result << (lookup(key.to_s + index.to_s) || ' ')
					result << text.to_s
				}
				tail = lookup(key.to_s + args.size.to_s)
				result << tail if(tail)
			else
				result = @dictionary[key] if @dictionary
				if(result.is_a? Proc)
					result.call
				elsif(result.nil?)
					def_lan = @session.default_language
					if(dict = self::class::DICTIONARIES[def_lan])
						dict[key]
					end
				else
					result
				end
			end
		end
		def format_date(date)
			date.strftime(lookup(:date_format))
		end
		def format_price(price)
			sprintf('%.2f', price.to_f/100.0) if price.to_i > 0
		end
		def navigation(filter=false)
			@session.navigation
		end
		def resource(rname, rstr=nil)
			collect_resource([self::class::RESOURCE_BASE, @session.flavor], 
				rname, rstr)
		end
		def resource_global(rname, rstr=nil)
			collect_resource([self::class::RESOURCE_BASE], rname, rstr)
		end
		def resource_localized(rname, rstr=nil, lang=@language)
			result = resource([rname, lang].join('_').intern, rstr)
			if(result.nil? && (lang != @session.default_language))
				result = resource_localized(rname, rstr, @session.default_language)
			end
			result
		end
		def zone_navigation
			@session.zone_navigation
		end
		private
		def collect_resource(base, rname, rstr=nil)
			varpart = self::class::RESOURCES[rname]
			if(varpart.is_a?(Array))
				varpart.collect { |part|
					[base, part, rstr].flatten.compact.join('/')
				}
			else
				[base, varpart, rstr].flatten.compact.join('/')
			end
		end
    def set_dictionary(language)
      @dictionary = self::class::DICTIONARIES[language] || {}
    end
  end
end
