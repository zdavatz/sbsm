#!/usr/bin/env ruby
# TestTransHandler -- sbsm -- 23.09.2004 -- hwyss@ywesee.com

$: << File.dirname(__FILE__)
$:.unshift File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'sbsm/trans_handler'
require 'cgi'
require 'fileutils'

module Apache
	DECLINED = 0
end
module SBSM
	class TestTransHandler < Test::Unit::TestCase
		class RequestStub
			attr_accessor :uri, :notes, :server
		end
		class ServerStub 
			attr_accessor :document_root
			def log_notice(fmt, *args)
			end
		end
		class NotesStub < Hash
			alias :add :store
		end
		def setup
			@doc_root = File.expand_path('data/htdoc', File.dirname(__FILE__))
			@etc_path = File.expand_path('../etc', @doc_root)
			@doc_root.taint
		end
		def teardown
			FileUtils.rm_r(@etc_path) if(File.exist?(@etc_path))
		end
		def test_parser_name
			assert_equal('uri', TransHandler.instance.parser_name)
			assert_equal('flavored_uri', 
				FlavoredTransHandler.instance.parser_name)
			assert_not_equal(TransHandler.instance.uri_parser, 
				FlavoredTransHandler.instance.uri_parser)
		end
		def test_translate_uri
			request = RequestStub.new
			request.server = ServerStub.new

			request.uri = '/'
			request.notes = NotesStub.new
			TransHandler.instance.translate_uri(request)
			assert_equal({}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/fr'
			request.notes = NotesStub.new
			TransHandler.instance.translate_uri(request)
			assert_equal({'language' => 'fr'}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/en/'
			request.notes = NotesStub.new
			TransHandler.instance.translate_uri(request)
			assert_equal({'language' => 'en'}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/search/state_id/407422388/search_query/ponstan'
			request.notes = NotesStub.new
			TransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'event'				=>	'search',
				'state_id'		=>	'407422388',
				'search_query'=>	'ponstan',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/search/state_id/407422388/search_query/ponstan/page/4'
			request.notes = NotesStub.new
			TransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'event'				=>	'search',
				'state_id'		=>	'407422388',
				'search_query'=>	'ponstan',
				'page'				=>	'4',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/search/pretty//state_id/407422388/search_query/ponstan/page/4'
			request.notes = NotesStub.new
			expected = '/index.rbx?language=de&event=search&pretty=&state_id=407422388&search_query=ponstan&page=4'
			TransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'event'				=>	'search',
				'pretty'			=>	'',
				'state_id'		=>	'407422388',
				'search_query'=>	'ponstan',
				'page'				=>	'4',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/search/search_query/'
			request.notes = NotesStub.new
			TransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'event'				=>	'search',
				'search_query'=>	'',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)
		end
		def test_translate_uri__shortcut
			request = RequestStub.new
			request.server = ServerStub.new
			request.server.document_root = @doc_root

			request.uri = '/shortcut'
			request.notes = NotesStub.new
			assert_nothing_raised { 
				TransHandler.instance.translate_uri(request)
			}
			assert_equal({}, request.notes)
			assert_equal('/shortcut', request.uri)
			
			FileUtils.mkdir_p(@etc_path)
			shortcut = File.join(@etc_path, 'shortcuts.rb')
			File.open(shortcut, 'w') { |fh|
				fh.puts <<-EOS
					'/shortcut'	=>	{	'shortcut'	=>	'variables'},
					'/somewhere'=>  {	'over'			=>	'the rainbow',
														'goodbye'		=>	'yellow brick road'},
				EOS
			}
			
			request.uri = '/shortcut'
			request.notes = NotesStub.new
			assert_nothing_raised {
				# run in safe-mode
				Thread.new {
					$SAFE = 1
					TransHandler.instance.translate_uri(request)
				}.join
			}
			assert_equal({'shortcut' => 'variables'}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/somewhere'
			request.notes = NotesStub.new
			TransHandler.instance.translate_uri(request)
			expected = {
				'over'		=>	'the rainbow',
				'goodbye'	=>	'yellow brick road',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)
		end
	end
	class TestFlavoredTransHandler < Test::Unit::TestCase
		class RequestStub
			attr_accessor :uri, :notes, :server
		end
		class ServerStub 
			attr_accessor :document_root
			def log_notice(fmt, *args)
			end
		end
		class NotesStub < Hash
			alias :add :store
		end
		def setup
			@doc_root = File.expand_path('data/htdoc', File.dirname(__FILE__))
			@etc_path = File.expand_path('../etc', @doc_root)
			@doc_root.taint
		end
		def teardown
			FileUtils.rm_r(@etc_path) if(File.exist?(@etc_path))
		end
		def test_translate_uri
			request = RequestStub.new
			request.server = ServerStub.new

			request.uri = '/'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			assert_equal({}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/fr'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			assert_equal({'language' => 'fr'}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/en/'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			assert_equal({'language' => 'en'}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/en/flavor'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			expected = {
				'language'=>	'en',
				'flavor'	=>	'flavor',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/en/other'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			expected = {
				'language'=>	'en',
				'flavor'	=>	'other',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/gcc/search/state_id/407422388/search_query/ponstan'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'flavor'			=>	'gcc',
				'event'				=>	'search',
				'state_id'		=>	'407422388',
				'search_query'=>	'ponstan',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/gcc/search/state_id/407422388/search_query/ponstan/page/4'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'flavor'			=>	'gcc',
				'event'				=>	'search',
				'state_id'		=>	'407422388',
				'search_query'=>	'ponstan',
				'page'				=>	'4',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/gcc/search/pretty//state_id/407422388/search_query/ponstan/page/4'
			request.notes = NotesStub.new
			expected = '/index.rbx?language=de&flavor=gcc&event=search&pretty=&state_id=407422388&search_query=ponstan&page=4'
			FlavoredTransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'flavor'			=>	'gcc',
				'event'				=>	'search',
				'pretty'			=>	'',
				'state_id'		=>	'407422388',
				'search_query'=>	'ponstan',
				'page'				=>	'4',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/de/gcc/search/search_query/'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			expected = {
				'language'		=>	'de',
				'flavor'			=>	'gcc',
				'event'				=>	'search',
				'search_query'=>	'',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)
		end
		def test_translate_uri__shortcut
			request = RequestStub.new
			request.server = ServerStub.new
			request.server.document_root = @doc_root

			request.uri = '/shortcut'
			request.notes = NotesStub.new
			assert_nothing_raised { 
				FlavoredTransHandler.instance.translate_uri(request)
			}
			assert_equal({}, request.notes)
			assert_equal('/shortcut', request.uri)
			
			FileUtils.mkdir_p(@etc_path)
			shortcut = File.join(@etc_path, 'shortcuts.rb')
			File.open(shortcut, 'w') { |fh|
				fh.puts <<-EOS
					'/shortcut'	=>	{	'shortcut'	=>	'variables'},
					'/somewhere'=>  {	'over'			=>	'the rainbow',
														'goodbye'		=>	'yellow brick road'},
				EOS
			}
			
			request.uri = '/shortcut'
			request.notes = NotesStub.new
			assert_nothing_raised {
				# run in safe-mode
				Thread.new {
					$SAFE = 1
					FlavoredTransHandler.instance.translate_uri(request)
				}.join
			}
			assert_equal({'shortcut' => 'variables'}, request.notes)
			assert_equal('/index.rbx', request.uri)

			request.uri = '/somewhere'
			request.notes = NotesStub.new
			FlavoredTransHandler.instance.translate_uri(request)
			expected = {
				'over'		=>	'the rainbow',
				'goodbye'	=>	'yellow brick road',
			}
			assert_equal(expected, request.notes)
			assert_equal('/index.rbx', request.uri)
		end
	end
end
