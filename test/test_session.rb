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
#	ywesee - intellectual capital connected, Winterthurerstrasse 52, CH-8006 Z�rich, Switzerland
#	hwyss@ywesee.com
#
# TestSession -- sbsm -- 22.10.2002 -- hwyss@ywesee.com 

require 'test/unit'
require 'sbsm/session'
require 'htmlgrid/component'

class StubSessionUnknownUser
end
class StubSessionApp
	def unknown_user
		StubSessionUnknownUser.new
	end
	def login(session)
		false
	end
	def async(&block)
		block.call
	end
end
class StubSessionValidator
	def reset_errors; end
	def validate(key, value, mandatory=false)
		value
	end
	def valid_values(key)
		if(key=='foo')
			['foo', 'bar']
		end
	end
	def error?
		false
	end
end
class StubSessionRequest < Hash
	def params
		self
	end
end
class StubSessionView < HtmlGrid::Component
	HTTP_HEADERS = {
		"foo"	=>	"bar"
	}
	def to_html(context)
		'0123456789' * 3
	end
end
class StubSessionBarState < SBSM::State
	EVENT_MAP = {
		:foobar	=>	StubSessionBarState
	}
end	
class StubSessionBarfoosState < SBSM::State
	DIRECT_EVENT = :barfoos
end
class StubSessionFooState < SBSM::State
	EVENT_MAP = {
		:bar	=>	StubSessionBarState
	}
end
class StubSessionState < SBSM::State
	VIEW = StubSessionView
	attr_accessor :volatile
	def foo
		@foo ||= StubSessionFooState.new(@session,@model)
	end
end
class StubVolatileState < SBSM::State
	VOLATILE = true
end
class Session < SBSM::Session
	DEFAULT_STATE = StubSessionState
	DRB_LOAD_LIMIT = 10
	CAP_MAX_THRESHOLD = 3
	MAX_STATES = 3
	DEFAULT_FLAVOR = 'gcc'
	attr_accessor :user, :state
	attr_accessor :attended_states, :cached_states
	attr_writer :lookandfeel, :persistent_user_input
	attr_writer :active_state
	public :active_state
end
class StubSessionSession < SBSM::Session
	attr_accessor :lookandfeel
	attr_accessor :persistent_user_input
	DEFAULT_FLAVOR = 'gcc'
	LF_FACTORY = {
		'gcc'	=>	'ccg',
		'sbb'	=>	'bbs',
	}
	def initialize(*args)
		super
		persistent_user_input = {}
	end
	def persistent_user_input(key)
		super
	end
end

class TestSession < Test::Unit::TestCase
	def setup
		@session = Session.new("test", StubSessionApp.new, StubSessionValidator.new)
		@request = StubSessionRequest.new
		@state = StubSessionState.new(@session, nil)
	end
	def test_attended_states_store
		@session.process(@request)
		state = @session.state
		expected = {
			state.id => state
		}
		#puts 'test'
		#puts @state
		assert_equal(expected, @session.attended_states)
	end
	def test_attended_states_cap_max
		req1 = StubSessionRequest.new
		@session.process(req1)
		state1 = @session.state
		req2 = StubSessionRequest.new
		req2["event"] = "foo"	
		@session.process(req2)
		state2 = @session.state
		assert_not_equal(state1, state2)
		req3 = StubSessionRequest.new
		req3["event"] = :bar	
		@session.process(req3)
		state3 = @session.state
		assert_not_equal(state1, state3)
		assert_not_equal(state2, state3)
		attended = {
			state1.id => state1,
			state2.id => state2,
			state3.id => state3,
		}
		assert_equal(attended, @session.attended_states)
		req4 = StubSessionRequest.new
		req4["event"] = :foobar	
		@session.process(req4)
		state4 = @session.state
		assert_not_equal(state1, state4)
		assert_not_equal(state2, state4)
		assert_not_equal(state3, state4)
		attended = {
			state2.id => state2,
			state3.id => state3,
			state4.id => state4,
		}
		assert_equal(attended, @session.attended_states)
		@session.process(req2)
		assert_equal(attended, @session.attended_states)
		req5 = StubSessionRequest.new
		req5["event"] = :bar	
		@session.process(req5)
		state5 = @session.state
		assert_not_equal(state1, state5)
		assert_not_equal(state2, state5)
		assert_not_equal(state3, state5)
		assert_not_equal(state4, state5)
		attended = {
			state2.id => state2,
			state4.id => state4,
			state5.id => state5,
		}
		assert_equal(attended, @session.attended_states)
	end
	def test_active_state1
		# Szenarien
		# - Keine State-Information in User-Input
		# - Unbekannter State in User-Input
		# - Bekannter State in User-Input

		state = StubSessionState.new(@session, nil)
		@session.attended_states = {
			state.id =>	state,
		}
		@session.active_state = @state
		assert_equal(@state, @session.active_state)
	end
	def test_active_state2
		# Szenarien
		# - Keine State-Information in User-Input
		# - Unbekannter State in User-Input
		# - Bekannter State in User-Input

		state = StubSessionState.new(@session, nil)
		@session.attended_states = {
			state.id =>	state,
		}
		@session.active_state = @state
		@request.store('state_id', state.id.next)
		@session.process(@request)
		assert_equal(@state, @session.active_state)
	end
	def test_active_state3
		# Szenarien
		# - Keine State-Information in User-Input
		# - Unbekannter State in User-Input
		# - Bekannter State in User-Input

		state = StubSessionState.new(@session, nil)
		@session.attended_states = {
			state.id =>	state,
		}
		@session.state = @state
		@request.store('state_id', state.id)
		@session.process(@request)
		assert_equal(state, @session.active_state)
	end
	def test_volatile_state
		state = StubSessionState.new(@session, nil)
		volatile = StubVolatileState.new(@session, nil)
		state.volatile = volatile
		@session.active_state = state
		@session.state = state
		@request.store('event', :volatile)
		newstate = @session.process(@request)
		assert_equal(:volatile, @session.event)
		assert_equal(volatile, @session.state)
		assert_equal(state, @session.active_state)
		@request.store('event', :foo)
		newstate = @session.process(@request)
		assert_equal(state.foo, @session.state)
		assert_equal(state.foo, @session.active_state)
	end
  def test_cgi_compatible
    assert_respond_to(@session, :restore)
    assert_respond_to(@session, :update)
    assert_respond_to(@session, :close)
    assert_respond_to(@session, :delete)
  end
  def test_restore
    assert_equal(@session, @session.restore[:proxy])
  end
	def test_user_input_no_request
		assert_nil(@session.user_input(:no_input))
	end
	def test_user_input_nil
		@session.process(@request)
		assert_nil(@session.user_input(:no_input))
	end
  def test_user_input
		@request["foo"] = "bar"
		@request["baz"] = "zuv"
    @session.process(@request)
    assert_equal("bar", @session.user_input(:foo))
    assert_equal("zuv", @session.user_input(:baz))
    assert_equal("zuv", @session.user_input(:baz))
		result = @session.user_input(:foo, :baz)
		expected = {
			:foo	=>	'bar',
			:baz	=>	'zuv',
		}
		assert_equal(expected, result)
  end
	def test_user_input_hash
		@request["hash[1]"] = "4"
		@request["hash[2]"] = "5"
		@request["hash[3]"] = "6"
		@session.process(@request)
		hash = @session.user_input(:hash)
		assert_equal(Hash, hash.class)
		assert_equal(3, hash.size)
		assert_equal("4", hash["1"])
		assert_equal("5", hash["2"])
		assert_equal("6", hash["3"])
	end
	def test_http_headers
		expected = {
			"foo"	=>	"bar"
		}
		assert_equal(expected, @session.http_headers)
	end
	def test_http_protocol
		assert_equal("http", @session.http_protocol)
	end
	def test_login_fail_keep_user
		@session.login
		assert_equal(StubSessionUnknownUser, @session.user.class)
	end
	def test_logged_in
		assert_equal(StubSessionUnknownUser, @session.user.class)
		assert_equal(false, @session.logged_in?)
	end
	def test_valid_values
		assert_equal(['foo', 'bar'], @session.valid_values('foo'))
		assert_equal([], @session.valid_values('oof'))
	end
	def test_persistent_user_input
		@request["baz"] = "zuv"
    @session.process(@request)
		assert_equal("zuv", @session.persistent_user_input(:baz))
		@session.process(StubSessionRequest.new)
		assert_equal("zuv", @session.persistent_user_input(:baz))
		@request["baz"] = "bla"
    @session.process(@request)
		assert_equal("bla", @session.persistent_user_input(:baz))
	end
	def test_process
		state = StubSessionState.new(@session, nil)
		@session.attended_states = {
			state.id =>	state,
		}
		@session.state = @state
		expected = state.foo
		@request.store('state_id', state.id)
		@request.store('event', :foo)
		@session.process(@request)
		assert_equal(expected, @session.state) 
		assert_equal(expected, @session.attended_states[expected.id])
		assert_equal(expected, @session.cached_states[:foo]) 
	end
	def test_process2
		@session.active_state = StubSessionBarfoosState.new(@session, nil)
		@session.process(@request)
		assert_equal([:barfoos], @session.cached_states.keys) 
	end
	def test_cached_state
		@request['event'] = :foo
		@session.process(@request)
		assert_equal(StubSessionFooState, @session.state.class)
		@request['event'] = :bar
		@session.process(@request)
		assert_equal(StubSessionBarState, @session.state.class)
		@request['event'] = :foo
		@session.process(@request)
		assert_equal(StubSessionFooState, @session.state.class)
	end
	def test_next_html_packet
		assert_equal('0123456789', @session.next_html_packet)
		assert_equal('0123456789', @session.next_html_packet)
		assert_equal('0123456789', @session.next_html_packet)
		assert_equal(nil, @session.next_html_packet)
	end
	def test_logout
		state = StubSessionBarState.new(@session, nil)
		@session.cached_states.store(:event, state)
		@session.attended_states.store(state.id, state)
		assert_equal(state, @session.cached_states[:event])
		assert_equal(state, @session.attended_states[state.id])
		@session.logout
		assert_equal(true, @session.cached_states.empty?)
		assert_equal(true, @session.attended_states.empty?)
	end
	def test_lookandfeel
		@session.lookandfeel=nil
		@session.persistent_user_input = {
			:flavor => 'some',
		}
		lnf = @session.lookandfeel
		assert_equal('gcc', @session.flavor)
		assert_equal('gcc', lnf.flavor)
		assert_instance_of(SBSM::Lookandfeel, lnf)
		lnf2 = @session.lookandfeel
		#assert_equal(lnf, lnf2)
		@session.persistent_user_input = {
			:flavor => 'other',
		}
		lnf3 = @session.lookandfeel
		assert_instance_of(SBSM::Lookandfeel, lnf)
		assert_not_equal(lnf, lnf3)
	end
	def test_lookandfeel2
		session = StubSessionSession.new("test", StubSessionApp.new, StubSessionValidator.new)
		session.lookandfeel=nil
		session.persistent_user_input = {
			:flavor => 'gcc',
		}
		lnf = session.lookandfeel
		assert_equal('gcc', session.flavor)
	end
	def test_lookandfeel3
		session = StubSessionSession.new("test", StubSessionApp.new, StubSessionValidator.new)
		session.lookandfeel=nil
		lnf2 = session.lookandfeel
		session.persistent_user_input = {
			:flavor => 'other',
		}
		assert_equal('gcc', session.flavor)
	end
end
