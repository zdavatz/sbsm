#!/usr/bin/env ruby
# TransHandler -- sbsm -- 23.09.2004 -- hwyss@ywesee.com

require 'rockit/rockit'
require 'cgi'

module SBSM
	module TransHandler
		GRAMMAR_PATH = File.expand_path('../../data/uri.grammar', 
			File.dirname(__FILE__))
		PARSER_PATH = File.expand_path('uri_parser.rb', 
			File.dirname(__FILE__))
		@@empty_check ||= nil
		@@lang_check ||= nil
		@@uri_parser ||= nil
		def canonical_uri(uri)
			@@uri_parser = self.uri_parser if(@@uri_parser.nil?)
			ast = @@uri_parser.parse(uri)
			values = []
			ast.children_names.each { |name|
				case name
				when'language', 'flavor', 'event'
					values.push([name, ast.send(name).value])
				when 'variables'
					ast.variables.each { |pair|
						key = pair.key.value
						val = if(pair.children_names.include?('value'))
							pair.value.value
						else
							''
						end
						values.push([key, val])
					}
				end
			}
			parts = [
				"/index.rbx", 
				values.collect { |pair| pair.join('=') }.join('&')
			]
			parts.delete('')
			parts.compact.join('?')
		end
		def parse_uri(request)
			@@uri_parser = self.uri_parser if(@@uri_parser.nil?)
			ast = @@uri_parser.parse(request.uri)
			values = request.notes
			ast.children_names.each { |name|
				case name
				when'language', 'flavor', 'event'
					values.add(name, ast.send(name).value)
				when 'variables'
					ast.variables.each { |pair|
						key = pair.key.value
						val = if(pair.children_names.include?('value'))
							CGI.unescape(pair.value.value.to_s)
						else
							''
						end
						values.add(key, val)
					}
				end
			}
			parts = [
				"/index.rbx", 
				values.collect { |pair| pair.join('=') }.join('&')
			]
		end
		def translate_uri(request)
			@@empty_check = Regexp.new('^/?$')
			@@lang_check = Regexp.new('^/[a-z]{2}(/|$)')
			uri = request.uri
			case uri
			when @@empty_check
				request.uri = '/index.rbx'
			when @@lang_check
				self.parse_uri(request)
				request.uri = '/index.rbx'
				#request.uri = canonical_uri(uri)
			end
			Apache::DECLINED
		end
		def uri_parser(grammar_path=GRAMMAR_PATH, parser_path=PARSER_PATH)
			if(File.exist?(grammar_path))
				oldpath = File.expand_path("_" << File.basename(grammar_path), 
					File.dirname(grammar_path))
				src = File.read(grammar_path)
				unless(File.exists?(oldpath) && File.read(oldpath)==src)
					File.delete(oldpath) if File.exists?(oldpath)
					Parse.generate_parser_from_file_to_file(grammar_path, 
						parser_path, '_uri_parser', 'SBSM')
					File.open(oldpath, 'w') { |f| f << src }
				end
			end
			require parser_path
			SBSM._uri_parser
		end
		module_function :canonical_uri
		module_function :translate_uri
		module_function :parse_uri
		module_function :uri_parser
	end
end
