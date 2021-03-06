#!/usr/bin/env ruby
# encoding: utf-8
#--
# Turing -- SBSM -- 15.05.2009 -- hwyss@ywesee.com
#++
# Use a Hash instead of a PStore to manage Captchas
require 'turing'
require 'thread'

module SBSM
  class PStore < Hash
    def initialize *args
      super
      @mutex = Mutex.new
    end
    def transaction &block
      @mutex.synchronize &block
    end
  end
end
class Turing::Challenge
  alias :__orig_initialize__ :initialize
  def initialize *args
    __orig_initialize__ *args
    @store = SBSM::PStore.new
  end
end
