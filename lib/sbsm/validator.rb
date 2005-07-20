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
# Validator -- sbsm -- 15.11.2002 -- hwyss@ywesee.com 

require 'digest/md5'
require 'tmail'
require 'date'
require 'drb/drb'
require 'uri'

module SBSM
	class InvalidDataError < RuntimeError
		attr_reader :key, :value
		alias :data :value 
		def initialize(msg, key, value)
			super(msg.to_s)
			@key = key
			@value = value
		end
	end
	class Validator
		BOOLEAN = []
		DATES = []
		ENUMS = {}
		EVENTS = []
		FILES = []
		NUMERIC = []
		PATTERNS = {}
		STRINGS = []
		URIS = []
		def initialize
			reset_errors()
			@boolean = self::class::BOOLEAN.dup
			@dates = self::class::DATES.dup
			@enums = self::class::ENUMS.dup
			@events = self::class::EVENTS.dup
			@files = self::class::FILES.dup
			@numeric = self::class::NUMERIC.dup
			@patterns = self::class::PATTERNS.dup
			@strings = self::class::STRINGS.dup
			@uris = self::class::URIS.dup
		end	
		def error?
			!@errors.empty?
		end
		def reset_errors
			@errors = {}
		end	
		def valid_values(key)
			key = key.intern if key.is_a? String
			@enums[key]
		end
		def validate(key, value)
			value = value.pop if value.is_a? Array
			return nil if value.nil?
			if(value.is_a? DRb::DRbObject)
				value = value[0]
				if(@files.include?(key))
					return validate_file(key, value)
				else
					begin
						value = value.read
					rescue StandardError => e
						p e
					end
				end
			end
			if(value.is_a? String)
				value = Iconv.iconv('ISO-8859-1', 'UTF8', value).pop if value.index("\303")
			end
			value = value.to_s.strip
			begin
				if(key==:event)
					value.intern if @events.include?(value.intern)
				elsif(@boolean.include?(key))
					validate_boolean(key, value)
				elsif(@dates.include?(key))
					validate_date(key, value)
				elsif(@enums.has_key?(key))
					value if @enums[key].include?(value)
				elsif(@patterns.include?(key))
					validate_pattern(key, value)
				elsif(@numeric.include?(key))
					validate_numeric(key, value)
				elsif(@uris.include?(key))
					validate_uri(key, value)
				elsif(@strings.include?(key))
					validate_string(value)
				elsif(self.respond_to?(key, true))
					self.send(key, value)
				end
			rescue InvalidDataError => e
				@errors.store(e.key, e)
			end
		end
		private
		def email(value)
			begin
				if(TMail::Address.parse(value).domain)
					value
				else
					raise InvalidDataError.new(:e_domainless_email_address, :email, value)
				end
			rescue TMail::SyntaxError => e
				raise InvalidDataError.new(:e_invalid_email_address, :email, value)
			end
		end
		def filename(value)
			if(value == File.basename(value))
				value
			end
		end
		def flavor(value)
			validate_string(value)
		end
		alias :default_flavor :flavor
		def language(value)
			validate_string(value)
		end
		def pass(value)
			Digest::MD5::hexdigest(value)
		end
		alias :confirm_pass :pass
		def state_id(value)
			if(match = /-?\d+/.match(value))
				match[0].to_i
			else
				nil
			end
		end
		def validate_boolean(key, value)
			case value.to_s.downcase
			when 'true', '1', 'y', 'j'
				true
			when 'false', '0', 'n'
				false
			else 
				raise InvalidDataError.new(:e_invalid_boolean, key, value)
			end
		end
		def validate_file(key, value)
			return nil if value.original_filename.empty?
			value
		end
		def validate_numeric(key, value)
			if(match = /\d*(\.\d{1,2})?/.match(value))
				match[0]
			else
				raise InvalidDataError.new(:e_invalid_numeric_format, key, value)
			end
		end
		def validate_string(value)
			value
		end
		def validate_date(key, value)
			return nil if (value.empty?)
			begin
				Date.parse(value.tr('.', '-'))
			rescue ArgumentError
				raise InvalidDataError.new(:e_invalid_date, key, value)
			end
		end
		def validate_pattern(key, value)
			pattern = @patterns[key] 
			if(match = pattern.match(value))
				match[0]
			end
		end
		def validate_string(value)
			value
		end
		def validate_date(key, value)
			return nil if (value.empty?)
			begin
				Date.parse(value.tr('.', '-'))
			rescue ArgumentError
				raise InvalidDataError.new(:e_invalid_date, key, value)
			end
		end
		def validate_uri(key, value)
			uri = URI.parse(value)
			if(uri.scheme.nil?)
				uri = URI.parse('http://' << value)
			end
			uri
		rescue 
			raise InvalidDataError.new(:e_invalid_uri, key, value)
		end
	end
end
