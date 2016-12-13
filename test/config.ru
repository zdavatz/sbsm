#\ -w -p 6789
# 6789 must be in sync with TEST_APP_URI from test_application.rb
root_dir = File.expand_path(File.join(__FILE__, '..', '..'))
$LOAD_PATH << File.join(root_dir, 'test')
require 'simple_sbsm'
@test_logger = ChronoLogger.new(File.join(root_dir, 'test.log'))
use Rack::CommonLogger, @test_logger
use Rack::Reloader, 0
use Rack::ContentLength
use(Rack::Static, urls: ["/doc/"])
SBSM.logger=@test_logger
app = Rack::ShowExceptions.new(Rack::Lint.new(Demo::SimpleSBSM.new(cookie_name: ::TEST_COOKIE_NAME)))
run app
