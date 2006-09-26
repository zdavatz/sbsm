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
# Session -- sbsm -- 22.10.2002 -- hwyss@ywesee.com 

require 'sbsm/cgi'
require 'sbsm/drb'
require 'sbsm/state'
require 'sbsm/lookandfeelfactory'
require 'delegate'

module SBSM
  class	Session < SimpleDelegator
		attr_reader :user, :active_thread, :app, :key, :cookie_input, 
			:unsafe_input, :valid_input, :request_path
		include DRbUndumped 
		CRAWLER_PATTERN = /archiver|slurp|bot|crawler|google|jeeves/i
		PERSISTENT_COOKIE_NAME = "sbsm-persistent-cookie"
		DEFAULT_FLAVOR = nil
		DEFAULT_LANGUAGE = nil
		DEFAULT_STATE = State
		DEFAULT_ZONE = nil
		DRB_LOAD_LIMIT = 255 * 102400
    EXPIRES = 60 * 60
		LF_FACTORY = nil
		LOOKANDFEEL = Lookandfeel
		CAP_MAX_THRESHOLD = 20
		MAX_STATES = 10
		SERVER_NAME = nil
		ARGV.push('') # satisfy cgi-offline prompt 
		@@cgi = CGI.new('html4')
    def initialize(key, app, validator=nil)
			touch()
      reset_input()
			reset_cookie()
      @app = app
			@html_packets = nil
      @key = key
			@validator = validator
			@attended_states = {}
			@persistent_user_input = {}
			logout()
			@active_state = @state = self::class::DEFAULT_STATE.new(self, @user)
			@attended_states.store(@state.object_id, @state)
			@unknown_user_class = @user.class
			@variables = {}
			super(app)
    end
		def cap_max_states
			if(@attended_states.size > self::class::CAP_MAX_THRESHOLD)
				#puts "too many states in session! Keeping only #{self::class::MAX_STATES}"
				#$stdout.flush
				sorted = @attended_states.values.sort
				sorted[0...(-self::class::MAX_STATES)].each { |state|
					state.__checkout
					@attended_states.delete(state.object_id)
				}
				## start GC if we are maxing out:
				Object.new
			end
		end
		def __checkout
			@attended_states.each_value { |state| state.__checkout }
			@attended_states.clear
			flavor = @persistent_user_input[:flavor]
			lang = @persistent_user_input[:language]
			@persistent_user_input.clear
			@persistent_user_input.store(:flavor, flavor)
			@persistent_user_input.store(:language, lang)
			@valid_input.clear
			@unsafe_input.clear
			@active_thread = nil
			true
		end
		def client_activex?
			if(@request.respond_to?(:user_agent))
				user_agent = @request.user_agent
				/MSIE/.match(user_agent) && /Win/i.match(user_agent)
			else
				false
			end
		end
		def client_nt5?
			if(@request.respond_to?(:user_agent))
				user_agent = @request.user_agent
				match = /Windows\s*NT\s*(\d+\.\d+)/i.match(user_agent)
				(match && (match[1].to_f >= 5))
			else
				false
			end
		end
		def cookie_set_or_get(key)
			if(value = @valid_input[key])
				set_cookie_input(key, value)
			else
				@cookie_input[key]
			end
		end
		def get_cookie_input(key)
			@cookie_input[key]
		end
		def cookie_name
			self::class::PERSISTENT_COOKIE_NAME	
		end
		def default_language
			self::class::DEFAULT_LANGUAGE
		end
		def direct_event
			@state.direct_event
		end
    def drb_process(request)
      process(request)
      to_html
    end
		def error(key)
			@state.error(key) if @state.respond_to?(:error)
		end
		def errors
			@state.errors.values if @state.respond_to?(:errors)
		end
		def error?
			@state.error? if @state.respond_to?(:error?)
		end
		def event
			@valid_input[:event]
		end
    def event_bound_user_input(key)
      @event_user_input ||= {}
      evt = state.direct_event
      @event_user_input[evt] ||= {}
      if(val = user_input(key))
        @event_user_input[evt][key] = val
      else
        @event_user_input[evt][key]
      end
    end
		def expired?
      Time.now - @mtime > EXPIRES
		end
		def force_login(user)
			@user = user
		end
		def identify_crawler(request)
			if(@is_crawler.nil? && request.respond_to?(:user_agent)) 
				@is_crawler = !!CRAWLER_PATTERN.match(request.user_agent)
			else
				@is_crawler
			end
		end
		def import_cookies(request)
			reset_cookie()
			if(cuki = request.cookies[self::class::PERSISTENT_COOKIE_NAME])
				cuki.each { |cuki_str|
					CGI.parse(cuki_str).each { |key, val|
						key = key.intern
						valid = @validator.validate(key, val.compact.last)
						@cookie_input.store(key, valid)
					}
				}
			end
		end
    def import_user_input(request)
			# attempting to read the cgi-params more than once results in a
			# DRbConnectionRefused Exception. Therefore, do it only once...
			return if(@user_input_imported) 
      reset_input()
      request.params.each { |key, value| 
				#puts "importing #{key} -> #{value}"
				index = nil
				@unsafe_input.push([key.to_s.dup, value.to_s.dup])
				unless(key.nil? || key.empty?)
					if match = /([^\[]+)\[([^\]]+)\]/.match(key)
						key = match[1]
						index = match[2]
						#puts key, index
					end
					key = key.intern 
					if(key == :confirm_pass)
						pass = request.params["pass"]
						#puts "pass:#{pass} - confirm:#{value}"
						@valid_input[key] = @valid_input[:set_pass] \
							= @validator.set_pass(pass, value)
					else
						valid = @validator.validate(key, value)
						if(index)
							(@valid_input[key] ||= {}).store(index, valid)
						else
							@valid_input[key] = valid
						end
					end
				end
				#puts "imported #{key} -> #{value} => #{@valid_input[key].inspect}"
      }
			@user_input_imported = true
			#puts @unsafe_input.inspect
			#puts @valid_input.inspect
			#$stdout.flush
    end
		def infos
			@state.infos if @state.respond_to?(:infos)
		end
		def info?
			@state.info? if @state.respond_to?(:info?)
		end
		def is_crawler?
			@is_crawler
		end
		def language
			cookie_set_or_get(:language) || default_language
		end
		def logged_in?
			!@user.is_a?(@unknown_user_class)
		end
		def login
			if(user = @app.login(self))
				@user = user
			end
		end
		def logout
			__checkout
			@user = @app.unknown_user()
		end
		def lookandfeel
			if(@lookandfeel.nil? \
				|| (@lookandfeel.flavor != flavor) \
				|| (@lookandfeel.language != persistent_user_input(:language)))
				@lookandfeel = if self::class::LF_FACTORY
					self::class::LF_FACTORY.create(self)
				else
					self::class::LOOKANDFEEL.new(self)
				end
			end
			@lookandfeel
		end
		def flavor
			@flavor ||= begin
				user_input = persistent_user_input(:flavor)
				user_input ||= @valid_input[:default_flavor]
				lf_factory = self::class::LF_FACTORY
				if(lf_factory && lf_factory.include?(user_input))
					user_input
				else	
					self::class::DEFAULT_FLAVOR
				end
			end
		end
		def http_headers
			@state.http_headers
		rescue NameError, StandardError
			{'Content-Type' => 'text/plain'}
		end
		def http_protocol
			@http_protocol ||=	if(@request.respond_to?(:server_port) \
														&& @request.server_port == 443)
														'https'
													else
														'http'
													end
		end
		def input_keys
			@valid_input.keys
		end
		def navigation
			@user.navigation
		end
		def next_html_packet
			@html_packets = to_html unless @html_packets
			if(@html_packets.empty?)
				## return nil
				@html_packets = nil
			else
				@html_packets.slice!(0, self::class::DRB_LOAD_LIMIT)
			end
		end
		def passthru(path)
			@request.passthru(path)
		end
		def persistent_user_input(key)
			if(value = user_input(key))
				@persistent_user_input.store(key, value)
			else
				@persistent_user_input[key]
			end
		end
		def process(request)
			begin
				identify_crawler(request)
				@request = request
        @request_method = request.request_method
				@validator.reset_errors() if @validator
				import_user_input(request)
				import_cookies(request)
				@state = active_state.trigger(event()) 
				@state.request_path ||= @request.unparsed_uri
        @state.init
				@state.reset_view
				unless @state.volatile?
					@active_state = @state
					@attended_states.store(@state.object_id, @state)
				end
				@zone = @active_state.zone
				@active_state.touch
				cap_max_states
			rescue StandardError => e
				puts "error in SBSM::Session#process"
				puts e.class
				puts e.message
				puts e.backtrace[0,8]
				$stdout.flush
			ensure
				@user_input_imported = false
			end
			''
		end
		def reset
=begin
			if(@active_thread \
				&& @active_thread.alive? \
				&& @active_thread != Thread.current)
				begin
					#@active_thread.exit
				rescue StandardError
				end
			end
			@active_thread = Thread.current
=end
			reset_input()
			@html_packets = nil
		end
		def reset_cookie
			@cookie_input = {}
		end
    def reset_input
      @valid_input = {}
			@processing_errors = {}
			@http_protocol = nil
			@flavor = nil
			@unsafe_input = []
    end
		def remote_addr
			@remote_addr ||= if @request.respond_to?(:remote_addr)
				@request.remote_addr
			end
		end
		def remote_ip
			@remote_ip ||= if(@request.respond_to?(:remote_host))
				@request.remote_host
			end
		end
		def set_cookie_input(key, val)
			@cookie_input.store(key, val)
		end
		def server_name
			@server_name ||= if @request.respond_to?(:server_name)
				@request.server_name 
			else
				self::class::SERVER_NAME
			end
		rescue DRb::DRbConnError
			@server_name = self::class::SERVER_NAME
		end
		def state(event=nil)
			@active_state
		end
    def touch
      @mtime = Time.now
      self
    end
		def to_html
			@state.to_html(@@cgi)
		rescue NameError, StandardError => err
			[ err.class, err.message ].concat(err.backtrace).join("\n")
		end
    def user_input(*keys)
			if(keys.size == 1)
				index = nil
				key = keys.first.to_s
				if match = /([^\[]+)\[([^\]]+)\]/.match(key)
					key = match[1]
					index = match[2]
				end
				key_sym = key.to_sym
				valid = @valid_input[key_sym]
				if(index && valid.respond_to?(:[]))
					valid[index]
				else
					valid
				end
			else
				keys.inject({}) { |inj, key|
					inj.store(key, user_input(key))
					inj
				}
			end
    end
		def valid_values(key)
			vals = @validator.valid_values(key) unless @validator.nil?
			vals || []
		end
		def warnings
			@state.warnings if @state.respond_to?(:warnings)
		end
		def warning?
			@state.warning? if @state.respond_to?(:warning?)
		end
    # CGI::SessionHandler compatibility
    def restore
			#puts "restore was called"
			#@unix_socket = DRb.start_service('drbunix:', self)
      hash = {
				#:proxy   =>  DRbObject.new(self, @unix_socket.uri)
				:proxy	=>	self,
      }
			hash.extend(DRbUndumped) # added for Ruby1.8 compliance
      hash
    end
    def update
      # nothing
    end
    def close
			#@unix_socket.stop_service
      # nothing
    end
    def delete
      @app.delete_session @key
    end
		def zone
			@valid_input[:zone] || @state.zone || self::class::DEFAULT_ZONE
		end
		def zones 
			@active_state.zones
		end
		def zone_navigation
			@state.zone_navigation
		end
		def ==(other)
			super
		end
		def <=>(other)
			self.weighted_mtime <=> other.weighted_mtime	
		end
		def [](key)
			@variables[key]
		end
		def []=(key, val)
			@variables[key] = val
		end
		private
		def active_state
			if(state_id = @valid_input[:state_id])
				@attended_states[state_id]
			end || @active_state
		end
		protected
		attr_reader :mtime
		def weighted_mtime
			@mtime + @user.session_weight
		end
  end
end
