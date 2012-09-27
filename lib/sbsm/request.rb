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
# SBSM::Request -- sbsm -- 27.09.2012 -- yasaka@ywesee.com
# SBSM::Request -- sbsm -- 24.01.2012 -- mhatakeyama@ywesee.com
# SBSM::Request -- sbsm -- hwyss@ywesee.com

require 'cgi'

require 'sbsm/cgi'
require 'sbsm/drb'
require 'cgi/session'
require 'cgi/drbsession'
require 'delegate'

module SBSM
  class Request < SimpleDelegator
    include DRbUndumped
    attr_reader :cgi
    def initialize(drb_uri, html_version = "html4", cgiclass = CGI)
      @cgi = cgiclass.new(html_version)
			@drb_uri = drb_uri
			@thread = nil
			@request = Apache.request
			super(@cgi)
    end
		def cookies
      @cgi.cookies
		end
    def is_crawler?
		  crawler_pattern = /archiver|slurp|bot|crawler|jeeves|spider|\.{6}/i
			!!crawler_pattern.match(@cgi.user_agent)
		end
		def passthru(path, disposition='attachment')
			@passthru = path
      @disposition = disposition
			''
		end
		def process
			begin
				@cgi.params.store('default_flavor', ENV['DEFAULT_FLAVOR'])
				@request.notes.each { |key, val|
					@cgi.params.store(key, val)
				}
        drb_process()
				#drb_request()
				#drb_response()
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
    def lock
      lock_file = '/tmp/sbsm_lock'
      open(lock_file, 'a') do |st|
        st.flock(File::LOCK_EX)
        yield
        st.flock(File::LOCK_UN)
      end
    end
    def drb_server_threads
      threads = 0
      status = '/var/www/oddb.org/doc/resources/downloads/status'
      if File.exist?(status)
        open(status) do |file|
          if file.gets =~ /threads:\s+(\d+)/
            threads = $1.to_i
          end
        end
      end
      threads
    end
    def drop_flag(flag = nil)
      file = '/tmp/sbsm_drop_flag'
      if flag != nil # write
        lock do 
          open(file, 'w') do |f|
            f.print flag.to_s
          end
        end
      else    # read
        unless File.exist?(file)
          lock do 
            open(file, 'w') do |f|
              f.print false
              flag = false
            end
          end
        else
          open(file, 'r') do |f|
            flag = if f.gets.chomp =~ /true/
                     true
                   else
                     false
                   end
          end
        end
      end
      flag
    end
    def check_threads
      time = Time.now.sec.to_i % 5 
      if time == 0
        #if drb_server_threads > 50
        if drb_server_threads > 30
          drop_flag true
        else
          drop_flag false
        end
      end
    end
    def is_drop?
      if unparsed_uri =~ /pointer/ or (is_crawler? && drop_flag)
        true
      end
    end
		def drb_process
      args = {
        'database_manager'	=>	CGI::Session::DRbSession,
				'drbsession_uri'		=>	@drb_uri,
				'session_path'			=>	'/',
      }
      check_threads
      if is_drop?
        return
      end
      if(is_crawler?)
        sleep 2.0
        sid = [ENV['DEFAULT_FLAVOR'], @cgi.params['language'], @cgi.user_agent].join('-')
        args.store('session_id', sid)
      end
			@session = CGI::Session.new(@cgi, args)
			@proxy = @session[:proxy]
			res = @proxy.drb_process(self)
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
					"#@disposition; filename=#{basename}")
				@request.headers_out.add('Content-Length',
					File.size(fullpath).to_s)
				begin
					File.open(fullpath) { |fd| @request.send_fd(fd) }
        rescue Errno::ENOENT, IOError => err
          @request.log_reason(err.message, @passthru)
          return Apache::NOT_FOUND
        end
			else
				begin
					headers = @proxy.http_headers
					unless(cookie_input.empty?)
						cookie = generate_cookie(cookie_input)
						headers.store('Set-Cookie', cookie.to_s)
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
			cookie_pairs = cookie_input.collect { |pair|
				pair.join('=')
			}.join(';')
			cookie_hash = {
				"name"		=>	@proxy.cookie_name || 'sbsm-persistent-cookie',
				"value"		=>	cookie_pairs,
				"path"		=>	"/",
				"expires"	=>	(Time.now + (60 * 60 * 24 * 365 * 10)),
			}
			CGI::Cookie.new(cookie_hash).to_s
		end
		def handle_exception(e)
			if defined?(Apache)
				msg = [
					[Time.now, self.object_id].join(' - '),
					e.class,
					e.message,
				].join(" - ")
        uri = unparsed_uri
        @request.log_reason(msg, uri)
				e.backtrace.each { |line|
					@request.log_reason(line, uri)
				}
			end
			hdrs = {
				'Status' => '302 Moved',
				'Location' => '/resources/errors/appdown.html',
			}
			@cgi.header(hdrs)
		end
  end
end
