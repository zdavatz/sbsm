#\ -w -p 6789
# 6789 must be in sync with TEST_APP_URI from test_application.rb
root_dir = File.expand_path(File.join(__FILE__, '..', '..'))
$LOAD_PATH << File.join(root_dir, 'test')
require 'simple_sbsm'
use Rack::CommonLogger, TEST_LOGGER
use Rack::Reloader, 0
use Rack::ContentLength
use(Rack::Static, urls: ["/doc/"])
app = Rack::ShowExceptions.new(Rack::Lint.new(Demo::SimpleSBSM.new(cookie_name: ::TEST_COOKIE_NAME)))
run app
