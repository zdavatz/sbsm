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
# TestIndex -- sbsm -- 04.03.2003 -- hwyss@ywesee.com 

$: << File.dirname(__FILE__)
$: << File.expand_path("../lib", File.dirname(__FILE__))

require 'test/unit'
require 'sbsm/index'

module SBSM
	class Index
		attr_accessor :values, :children
	end
end

class TestIndex < Test::Unit::TestCase
	def setup
		@index = SBSM::Index.new
		o2 = SBSM::Index.new
		o2.values = ['bar']
		o1 = SBSM::Index.new
		o1.children[?o] = o2
		f = SBSM::Index.new
		f.children[?o] = o1
		r = SBSM::Index.new
		r.values = ['foo']
		a = SBSM::Index.new
		a.children[?r] = r
		b = SBSM::Index.new
		b.children[?a] = a
		@index.children[?b] = b
		@index.children[?f] = f
	end
	def test_to_a
		assert_equal(['foo', 'bar'], @index.to_a)
	end
	def test_fetch1
		assert_equal(['bar'], @index.fetch('foo'))
	end
	def test_fetch2
		assert_equal([], @index.fetch('Foo'))
	end
	def test_fetch3
		@index.store('bar', ['foobar', 'babar'])
		assert_equal(['foo', ['foobar', 'babar']], @index['ba'])
	end
	def test_store1
		@index.store('bar', 'babar')
		assert_equal(['foo', 'babar'], @index.children[?b].children[?a].children[?r].values)
		assert_equal(['foo', 'babar'], @index['ba'])
	end
	def test_store2
		@index.store('bar', 'foobar', 'babar')
		assert_equal(['foo', 'foobar', 'babar'], @index.children[?b].children[?a].children[?r].values)
		assert_equal(['foo', 'foobar', 'babar'], @index['ba'])
	end
	def test_store3
		@index.store('bar', ['foobar', 'babar'])
		assert_equal(['foo', ['foobar', 'babar']], @index.children[?b].children[?a].children[?r].values)
	end	
	def test_replace
		@index.replace('foo', 'muh', 'bar')
		assert_equal(['bar'], @index.children[?m].children[?u].children[?h].values)
	end
	def test_delete
		@index.delete('foo', 'bar')
		assert_equal([], @index.children[?f].children[?o].children[?o].values)
	end
end
