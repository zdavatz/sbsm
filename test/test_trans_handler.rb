#!/usr/bin/env ruby
# TestTransHandler -- sbsm -- 23.09.2004 -- hwyss@ywesee.com

$: << File.dirname(__FILE__)
$:.unshift File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'sbsm/trans_handler'
require 'cgi'

module SBSM
	class TestTransHandler < Test::Unit::TestCase
		def test_canonical_uri
			uri = '/'
			expected = '/index.rbx'
			assert_equal(expected, TransHandler.canonical_uri(uri))
			uri = '/fr'
			expected = '/index.rbx?language=fr'
			assert_equal(expected, TransHandler.canonical_uri(uri))
			uri = '/en/'
			expected = '/index.rbx?language=en'
			assert_equal(expected, TransHandler.canonical_uri(uri))
			uri = '/en/flavor'
			expected = '/index.rbx?language=en&flavor=flavor'
			assert_equal(expected, TransHandler.canonical_uri(uri))
			uri = '/en/other/'
			expected = '/index.rbx?language=en&flavor=other'
			assert_equal(expected, TransHandler.canonical_uri(uri))
			uri = '/de/gcc/search/state_id/407422388/search_query/ponstan'
			expected = '/index.rbx?language=de&flavor=gcc&event=search&state_id=407422388&search_query=ponstan'
			assert_equal(expected, TransHandler.canonical_uri(uri))
			uri = '/de/gcc/search/state_id/407422388/search_query/ponstan/page/4'
			expected = '/index.rbx?language=de&flavor=gcc&event=search&state_id=407422388&search_query=ponstan&page=4'
			assert_equal(expected, TransHandler.canonical_uri(uri))
		end
	end
end
