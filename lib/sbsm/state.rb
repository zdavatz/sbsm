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
# State -- sbsm -- 22.10.2002 -- hwyss@ywesee.com 

module SBSM
	class ProcessingError < RuntimeError
		attr_reader :key, :value
		def initialize(message,	key, value)
			super(message)
			@key = key
			@value = value
		end
	end
	class Warning
		attr_reader :key, :value, :message
		def initialize(message, key, value)
			@message = message
			@key = key
			@value = value
		end
	end
	class State
		attr_reader :errors, :infos, :events, :previous, :warnings
		attr_accessor :next, :request_path
		DIRECT_EVENT = nil
		ZONE = nil
		ZONES = []
		ZONE_EVENT = nil
		EVENT_MAP = {}
		GLOBAL_MAP = {}
		REVERSE_MAP = {}
		VIEW = nil
		VOLATILE = false
		def State::direct_event
			self::DIRECT_EVENT
		end
		def State::zone
			self::ZONE
		end
		def State::zones
			self::ZONES
		end
		def initialize(session, model)
			@session = session
			@model = model
			@events = self::class::GLOBAL_MAP.dup.update(self::class::EVENT_MAP.dup)
			@view = nil
			@default_view = self::class::VIEW
			@errors = {}
			@infos = []
			@warnings = []
			touch()
			init()
		end
		def add_warning(message, key, value)
			if(key.is_a? String)
				key = key.intern
			end
			warning = Warning.new(message, key, value)
			@warnings.push(warning)
		end
		def back
			@previous
		end
		def __checkout
			return if(@checked_out)
			@checked_out = true
			reset_view
			@model = nil
			if(@next.respond_to?(:unset_previous))
				@next.unset_previous
			end
			@next = nil
			if(@previous.respond_to?(:__checkout))
				@previous.__checkout
			end
			@previous = nil
		end
		def create_error(msg, key, val)
			ProcessingError.new(msg.to_s, key, val)
		end
		def default 
			self
		end
		def direct_event
			self::class::DIRECT_EVENT
		end
		def error?
			!@errors.empty?
		end
		def error(key)
			@errors[key]
		end
		def error_check_and_store(key, value, mandatory=[])
			if(value.is_a? RuntimeError)
				@errors.store(key, value)
			elsif(mandatory.include?(key) && mandatory_violation(value))
				error = create_error('e_missing_' << key.to_s, key, value)
				@errors.store(key, error)
			end
		end
		def extend(mod)
			if(mod.constants.include?('VIRAL'))
				@viral_module = mod 
			end
			if(mod.constants.include?('EVENT_MAP'))
				@events.update(mod::EVENT_MAP)
			end
			super
		end
		def http_headers
			view.http_headers
		end
		def info?
			!@infos.empty?
		end
		def info(key)
			@infos[key]
		end
		def mandatory_violation(value)
			value.nil? || (value.respond_to?(:empty?) && value.empty?)
		end
		def previous=(state)
			if(@previous.nil? && state.respond_to?(:next=))
				state.next = self
				@previous = state
			end
		end
		def reset_view
			@view = nil
		end
		def sort
			return self unless @model.respond_to?(:sort!)
			get_sortby!
			@model.sort! { |a, b| compare_entries(a, b) }
			@model.reverse! if(@sort_reverse)
			self
		end
		def touch
			@mtime = Time.now
		end
		def to_html(context)
			view.to_html(context)
		end
		def trigger(event)
			@errors = {}
			@infos = []
			@warnings = []
			state = if(event && !event.to_s.empty? && self.respond_to?(event))
				self.send(event) 
			elsif(klass = @events[event])
				klass.new(@session, @model)
			end
			state ||= self.default
			if(state.respond_to?(:previous=))
				state.previous = self 
			end
			state 
		end
		def unset_previous
			@previous = nil
		end
		def warning(key)
			@warnings.select { |warning| warning.key == key }.first
		end
		def warning?
			!@warnings.empty?		
		end
		def user_input(keys=[], mandatory=[])
			keys = [keys] unless keys.is_a?(Array)
			mandatory = [mandatory] unless mandatory.is_a?(Array)
			if(hash = @session.user_input(*keys))
				hash.each { |key, value| 
					if(error_check_and_store(key, value, mandatory))
						hash.delete(key)
					end
				}
				hash
			else
				{}
			end
		end
		def view
			@view ||= begin
				klass = @default_view
				if(klass.is_a?(Hash))
					klass = klass.fetch(@session.user.class) {
						klass[:default]
					}
				end
				model = (@filter.is_a? Proc) ? @filter.call(@model) : @model
				klass.new(model, @session)	
			end
		end
		def volatile?
			self::class::VOLATILE
		end
		def zone 
			self::class::ZONE
		end
		def zones 
			self::class::ZONES
		end
		def zone_navigation
			[]
		end
		def <=>(other)
			@mtime <=> other.mtime
		end
		private
		def init
		end
		protected
		def compare_entries(a, b)
			@sortby.each { |sortby|
				aval, bval = nil
				begin
					aval = a.send(sortby)
					bval = b.send(sortby)
				rescue
					next
				end
				res = if (aval.nil? && bval.nil?)
					0
				elsif (aval.nil?)
					1
				elsif (bval.nil?)
					-1
				else 
					aval <=> bval
				end
				return res if(res.nonzero?)
			}
			0
		end
		def get_sortby!
			@sortby ||= []
			sortvalue = @session.user_input(:sortvalue).to_sym
			if(@sortby.first == sortvalue)
				@sort_reverse = !@sort_reverse 
			else
				@sort_reverse = self.class::REVERSE_MAP[sortvalue] 
			end
			@sortby.delete(sortvalue)
			@sortby.unshift(sortvalue)
		end
		attr_reader :mtime
	end
end
