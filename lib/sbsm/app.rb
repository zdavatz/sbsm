#!/usr/bin/env ruby
# encoding: utf-8
#--
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
# ngiger@ywesee.com
#
# App -- sbsm -- ngiger@ywesee.com
#++
require 'cgi'
require 'cgi/session'
require 'sbsm/cgi'
require 'cgi/drbsession'
require 'sbsm/drbserver'
module SBSM
  ###
  # App a base class for Webrick server
  class App < SBSM::DRbServer
    include DRbUndumped
    PERSISTENT_COOKIE_NAME = "cookie-persistent-sbsm-1.3.1"
    SBSM.info "PERSISTENT_COOKIE_NAME #{PERSISTENT_COOKIE_NAME}"

    attr_reader :sbsm, :my_self, :validator

    OPTIONS = [ :app, :config_file, :trans_handler, :validator, :persistence_layer, :server_uri, :session, :unknown_user ]
    COOKIE_ID = 'sbsm-persistent-cookie-id'

    OPTIONS.each{ |opt| eval "attr_reader :#{opt}" }

    # Base class for a SBSM based WebRick HTTP server
    # * offers a start_server() method to launch a DRB server for handling the DRB-requests
    # * offer a call(env) method form handling the WebRick requests
    # This is all what is needed to be compatible with WebRick
    #
    # === arguments
    #
    # * +validator+ -         A Ruby class overriding the SBSM::Validator class
    # * +trans_handler+ -     A Ruby class overriding the SBSM::TransHandler class
    # * +persistence_layer+ - Persistence Layer to use
    #
    # === Examples
    # Look at steinwies.ch
    # * https://github.com/zdavatz/steinwies.ch (simple, mostly static files, one form, no persistence layer)
    #
    def initialize(app:, validator:, trans_handler:, persistence_layer: nil)
      @app = app
      @trans_handler = trans_handler
      @validator = validator
      SBSM.info "initialize @app is now #{@app.class} validator #{validator} th #{trans_handler} "
      super(persistence_layer)
    end

    def call(env) ## mimick sbsm/lib/app.rb
      request = Rack::Request.new(env)
      response = Rack::Response.new
      if request.cookies[PERSISTENT_COOKIE_NAME] && request.cookies[PERSISTENT_COOKIE_NAME].length > 1
        session_id = request.cookies[PERSISTENT_COOKIE_NAME]
      else
        session_id = rand((2**(0.size * 8 -2) -1)*10240000000000).to_s(16)
      end
      file_name = File.expand_path(File.join('doc', request.path))
      if File.file?(file_name)
        if /css/i.match(File.basename(file_name))
          response.set_header('Content-Type', 'text/css')
        else
          response.set_header('Content-Type', 'text/plain')
        end
        response.write(File.open(file_name, File::RDONLY){|file| file.read})
        return response
      end

      return [400, {}, []] if /favicon.ico/i.match(request.path)
      SBSM.debug "#{request.path}: cookies are #{request.cookies} for session_id #{session_id}"
      @drb_uri ||= @app.drb_uri
      args = {
        'database_manager'  =>  CGI::Session::DRbSession,
        'drbsession_uri'    =>  @drb_uri,
        'session_path'      =>  '/',
        PERSISTENT_COOKIE_NAME => session_id,
      }
      @cgi = CGI.initialize_without_offline_prompt('html4')
      @session = CGI::Session.new(@cgi, args)
      saved = self[session_id]
      @proxy  = DRbObject.new(saved, server_uri)
      @proxy.trans_handler = @trans_handler
      @proxy.app = @app
      res = @proxy.drb_process(self, request)
      response.write res
      response.headers['Content-Type'] ||= 'text/html; charset=utf-8'
      response.set_cookie(PERSISTENT_COOKIE_NAME, session_id)
      @proxy.cookie_input.each{|key, value| response.set_cookie(key, value) }
      SBSM.debug "finish session_id #{session_id}: header #{response.headers}"
      response.finish
    end
  end
end
