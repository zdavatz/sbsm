#!/usr/bin/env ruby
# encoding: utf-8
$: << File.dirname(__FILE__)
$:.unshift File.expand_path('../lib', File.dirname(__FILE__))

ENV['RACK_ENV'] = 'test'
ENV['REQUEST_METHOD'] = 'GET'

require 'minitest/autorun'
require 'rack/test'
require 'sbsm/app'
require 'sbsm/session'
require 'simple_sbsm'
require 'nokogiri'
require 'rack/utils'

# Here we test, whether setting various class constant have the desired effect

class AppVariantTest < Minitest::Test
  include Rack::Test::Methods
  attr_reader :app
  def setup
    # @app = Demo::SimpleSBSM.new(cookie_name: TEST_COOKIE_NAME)
    @app = Demo::SimpleRackInterface.new
  end
  def test_post_feedback
    get '/de/page' do # needed to set cookie
      last_response.set_cookie(TEST_COOKIE_NAME, :value =>  Hash.new('anrede' => 'value2'))
    end
    clear_cookies
    set_cookie 'anrede=value2'
    set_cookie "_session_id=#{TEST_COOKIE_NAME}"
    get '/de/page/feedback' do
    end
    assert_equal  ["_session_id", 'anrede'], last_request.cookies.keys
    expected = {"_session_id"=>"test-cookie", "anrede"=>"value2"}
    assert_equal expected, last_request.cookies
    skip ('TODO: We should test test_post_feedback')
    assert_equal 'value2',  @app.last_session.persistent_user_input('anrede')
  end
  def test_session_home_en_and_fr
    get '/'
    get '/fr/page/about'
    assert last_response.ok?
    skip ('TODO: We should test test_session_home_en_and_fr')
    assert_match ABOUT_HTML_CONTENT, last_response.body
    get '/en/page/about'
    assert last_response.ok?
    assert_match ABOUT_HTML_CONTENT, last_response.body
    assert_equal(first_session_id, second_session_id)
  end
end

class AppTestSimple < Minitest::Test
  include Rack::Test::Methods
  attr_reader :app

  def setup
    @app = Demo::SimpleRackInterface.new
  end
  def test_post_feedback
    set_cookie "_session_id=#{TEST_COOKIE_NAME}"
    set_cookie "#{SBSM::Session::PERSISTENT_COOKIE_NAME}=dummy"
    get '/de/page/feedback' do
    end
    # assert_match /anrede.*=.*value2/, CGI.unescape(last_response.headers['Set-Cookie'])
    assert last_response.ok?
    assert_equal  ["_session_id", SBSM::Session::PERSISTENT_COOKIE_NAME], last_request.cookies.keys
    skip ('TODO: We should test test_post_feedback')
    assert_equal(FEEDBACK_HTML_CONTENT, last_response.body)

    set_cookie "anrede=Herr"
    post '/de/page/feedback', { anrede: 'Herr',  msg: 'SBSM rocks!',  state_id: '1245'} do
    end
    page = Nokogiri::HTML(last_response.body)
    puts page.text
    assert  page.css('input').find{|x| x.attributes['name'].value.eql?('state_id') }.attributes['value'].value
    state_id = page.css('input').find{|x| x.attributes['name'].value.eql?('state_id') }.attributes['value'].value.to_i
    assert state_id > 0
    post '/de/page/feedback', { 'anrede' => 'Herr', 'msg' => 'SBSM rocks!' , 'state_id' => '1245'}
    assert last_response.ok?
    assert last_response.headers['Content-Length'].to_s.length > 0
    assert_match CONFIRM_HTML_CONTENT, last_response.body
    post '/de/page/feedback', { 'confirm' => 'true', 'anrede' => 'Herr', 'msg' => 'SBSM rocks!' }
    assert last_response.ok?
    assert_match CONFIRM_DONE_HTML_CONTENT, last_response.body
  end

  def test_session_home
    get '/home'
    assert last_response.ok?
    assert_match /^request_path is \/home$/, last_response.body
    assert_match HOME_HTML_CONTENT, last_response.body
    assert_match /utf-8/i, last_response.headers['Content-Type']
  end

  def test_css_file
    css_content = "html { max-width: 960px; margin: 0 auto; }"
    css_file = File.join('doc/sbsm.css')
    FileUtils.makedirs(File.dirname(css_file))
    unless File.exist?(css_file)
      File.open(css_file, 'w+') do |file|
        file.puts css_content
      end
    end
    get '/sbsm.css'
    assert last_response.ok?
    assert_match css_content, last_response.body
  end
  def test_session_about_then_home
    skip ('TODO: We should test test_post_feedback')
    get '/de/page/about'
    assert last_response.ok?
    assert_match /^About SBSM: TDD ist great!/, last_response.body
    get '/de/page/home'
    assert last_response.ok?
    assert_match HOME_HTML_CONTENT, last_response.body
  end
  def test_default_content_from_home
    test_path = '/default_if_no_such_path'
    get test_path
    assert last_response.ok?
    assert_match /^#{HOME_HTML_CONTENT}/, last_response.body
    assert_match HOME_HTML_CONTENT, last_response.body
    assert_match /^request_path is /, last_response.body
    assert_match test_path, last_response.body
  end
  def test_session_id_is_maintained
    get '/'
    assert last_response.ok?
    body = last_response.body.clone
    assert_match /^request_path is \/$/, body
    assert_match /member_counter is 1$/, body
    assert_match HOME_HTML_CONTENT, body
    # Getting the request a second time must increment the class, but not the member counter
    m = /class_counter is (\d+)$/.match(body)
    counter = m[1]
    assert_match /class_counter is (\d+)$/, body
    get '/'
    assert last_response.ok?
    body = last_response.body.clone
    assert_match /^request_path is \/$/, body
    class_line = /class_counter.*/.match(body)[0]
    assert_match /class_counter is #{counter.to_i+1}$/, class_line
    skip ('TODO: We should test test_session_id_is_maintained')
    member_line = /member_counter.*/.match(body)[0]
    assert_match /member_counter is 1$/, member_line
  end
  def test_session_home_then_fr_about
    get '/home'
    assert last_response.ok?
    assert_match /^request_path is \/home$/, last_response.body
    skip ('TODO: We should test test_session_home_then_fr_about')
    get '/fr/page/about'
    assert last_response.ok?
    assert_match ABOUT_HTML_CONTENT, last_response.body
  end

  def test_session_cookies
    skip ('TODO: We should test test_session_cookies')
    def cookies(header)
      string =  header['Set-Cookie']
      hash = Rack::Utils.parse_cookies_header string
      to_return = {}
      hash.each do |key, value|
        if to_return.size == 0
          to_return[key] = { :value => value}
        else
          to_return[key] = value
        end
      end
      to_return
    end
    get '/home'
    assert last_response.ok?
    assert_match /^request_path is \/home$/, last_response.body
    first = cookies(last_response.headers.clone)
    assert(first.is_a?(Hash))
    assert(first['_session_id'])
    first_session_id = first['_session_id'][:value]
    get '/fr/page/about'
    assert last_response.ok?
    last = cookies(last_response.headers.clone)
    assert(last.is_a?(Hash))
    assert(last['_session_id'])
    last_session_id = last['_session_id'][:value]
    assert_equal(last_session_id, first_session_id)
  end

  def test_session_about_then_root
    get '/fr/page/about'
    assert last_response.ok?
    skip ('TODO: We should test test_session_about_then_root')
    assert_match ABOUT_HTML_CONTENT, last_response.body
    get '/'
    assert last_response.ok?
    assert_match HOME_HTML_CONTENT, last_response.body
  end

  def test_show_stats
    # We add it here to get some more or less useful statistics
    ::SBSM::Session.show_stats '/de/page'
  end

end
