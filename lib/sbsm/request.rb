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
# Request -- sbsm -- hwyss@ywesee.com

require 'sbsm/cgi'
require 'sbsm/drb'
require 'cgi/session'
require 'cgi/drbsession'
require 'delegate'

module SBSM
  class Request < SimpleDelegator
    include DRbUndumped
    attr_reader :cgi
    def initialize(drb_uri, html_version = "html4")
      @cgi = CGI.new(html_version)
			@drb_uri = drb_uri
			@thread = nil
			@request = Apache.request
			super(@cgi)
    end
		def abort
			@thread.exit
		end
		def cookies
			if(cuki = @request.headers_in['Cookie'])
				cuki.split(/\s*;\s*/).inject({}) { |cookies, cukip| 
					key, val = cukip.split(/\s*=\s*/, 2).collect { |str|
						CGI.unescape(str)
					}
					(cookies[key] ||= []).push(val)
					cookies
				}
			else
				{}
			end
		end
		def passthru(path)
			@passthru = path
			''
		end
		def process
			begin
				@cgi.params.store('default_flavor', ENV['DEFAULT_FLAVOR'])
				@request.notes.each { |key, val|
					@cgi.params.store(key, val)
				}
				@thread = Thread.new {
					Thread.current.priority=10
					drb_request()
					drb_response()
				}	
				@thread.join
			rescue StandardError => e
				handle_exception(e)
			ensure
				@session.close if @session.respond_to?(:close)
			end
		end
		def remote_host(lookup_type=Apache::REMOTE_NOLOOKUP)
			@request.remote_host(lookup_type)
		end
		def unparsed_uri
			@request.unparsed_uri
		end
		private
		def drb_request
			@session = CGI::Session.new(@cgi,
				'database_manager'	=>	CGI::Session::DRbSession,
				'drbsession_uri'		=>	@drb_uri,
				'session_path'			=>	'/')
			@proxy = @session[:proxy]
			@proxy.process(self)
		end
		def drb_response
			res = ''
			while(snip = @proxy.next_html_packet)
				res << snip
			end
			cookie_input = @proxy.cookie_input
			# view.to_html can call passthru instead of sending data
			if(@passthru) 
				unless(cookie_input.empty?)
					cookie = generate_cookie(cookie_input) 
					@request.headers_out.add('Set-Cookie', cookie.to_s)
				end
				# the variable @passthru is set by a trusted source
				basename = File.basename(@passthru)
				fullpath = File.expand_path(@passthru, 
					@request.server.document_root)
				fullpath.untaint
				subreq = @request.lookup_file(fullpath)
				@request.content_type = subreq.content_type
				@request.headers_out.add('Content-Disposition', 
					"attachment; filename=#{basename}")
				@request.headers_out.add('Content-Length', 
					File.size(fullpath).to_s)
				begin
					@cgi.out { File.read(fullpath) }
        rescue Errno::ENOENT, IOError => err
          @request.log_reason(err.message, @passthru)
          return Apache::NOT_FOUND
        end
			else
				begin
					headers = @proxy.http_headers
					unless(cookie_input.empty?)
						cookie = generate_cookie(cookie_input) 
						headers.store('Set-Cookie', [cookie])
					end
					@cgi.out(headers) { 
						(@cgi.params.has_key?("pretty")) ? CGI.pretty( res ) : res
					}
				rescue StandardError => e
					handle_exception(e)
				end
			end
		end
		def generate_cookie(cookie_input)
			cookie_pairs = cookie_input.collect { |*pair| 
					pair.join('=') 
			}
			cookie_hash = {
				"name"		=>	@proxy.cookie_name || 'sbsm-persistent-cookie',
				"value"		=>	cookie_pairs,
				"path"		=>	"/",
				"expires"	=>	(Time.now + (60 * 60 * 24 * 365 * 10)),
			}
			CGI::Cookie.new(cookie_hash)
		end
		def handle_exception(e)
			if defined?(Apache)
				msg = [
					[Time.now, id].join(' - '),
					e.class,
					e.message,
					e.backtrace,
				].flatten.join("\n")
				@request.server.log_error(msg)
			end
			hdrs = {
				'Status' => '302 Moved', 
				'Location' => '/resources/errors/appdown.html',
			}
			@cgi.header(hdrs)
		ensure
			@thread.exit 
			@proxy.active_thread.exit if @proxy
		end
  end
end
