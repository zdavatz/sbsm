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
# DrbServer -- sbsm -- hwyss@ywesee.com

require 'delegate'
require 'sbsm/session'
require 'sbsm/user'
require 'thread'
require 'digest/md5'

module SBSM
	class DRbServer < SimpleDelegator
		include DRbUndumped
		CLEANING_INTERVAL = 300
		CAP_MAX_THRESHOLD = 30
		ENABLE_ADMIN = false
		MAX_SESSIONS = 20
		RUN_CLEANER = true
		SESSION = Session
		UNKNOWN_USER = UnknownUser
		VALIDATOR = nil
		attr_reader :cleaner, :updater
		def initialize(persistence_layer=nil)
			@sessions = {}
			@mutex = Mutex.new
			@cleaner = run_cleaner if self::class::RUN_CLEANER
			@async = []
			super(persistence_layer)
		end
		def admin(src, priority=-1)
			return unless(self::class::ENABLE_ADMIN)
			Thread.current.priority = priority
			Thread.current.abort_on_exception = true
			target = @system
			begin
				response = target.instance_eval(src)
				response.to_s[0,72]
			rescue StandardError => error
				puts error.class
				puts error.message
				puts error.backtrace
				if(target.id == @system.id)
					target = self
					retry
				end
				error
			end
		end
		def async(&block)
			@async.push Thread.new(&block)
		end
		def cap_max_sessions
			if(@sessions.size > self::class::CAP_MAX_THRESHOLD)
				#puts "too many sessions! Keeping only #{self::class::MAX_SESSIONS}"
				sorted = @sessions.values.sort
				sorted[0...(-self::class::MAX_SESSIONS)].each { |sess|
					@sessions.delete(sess.key)
				}
			end
		end
		def clean
			loop {
				sleep self::class::CLEANING_INTERVAL
				@sessions.delete_if { |key, s| s.expired? }
				cap_max_sessions()
				@sessions.each { |key, s| s.cap_max_states }
				@async.delete_if { |thread| !thread.alive? }
			}
		end
		def clear
			@sessions.clear
		end
		def delete_session(key)
			@sessions.delete(key)
		end
		def run_cleaner
			# puts "running cleaner thread"
			Thread.new {
				Thread.current.abort_on_exception = true
				Thread.current.priority = 0
				clean()
			}
		end
		def unknown_user
			self::class::UNKNOWN_USER.new
		end
		def [](key)
			#@mutex.synchronize {
				unless(s = @sessions[key] and not s.expired?)
					args = [key, self]
					if(klass = self::class::VALIDATOR)
						args.push(klass.new)
					end
					s = @sessions[key] = self::class::SESSION.new(*args.compact)
				end
				#Thread.current.abort_on_exception = true
				Thread.current.priority = 3
				s.reset()
				Thread.current.priority = 0
				s.touch()
				s
			#}
		end
	end
end
