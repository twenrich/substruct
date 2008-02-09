require File.dirname(__FILE__) + '/../../../../test/test_helper' # the default rails helper

# ensure that the Engines testing enhancements are loaded.
require File.join(Engines.config(:root), "engines", "lib", "testing_extensions")

# force these config values
module Substruct
#  config :some_option, "some_value"
end

# Load the schema - if migrations have been performed, this will be up to date.
load(File.dirname(__FILE__) + "/../db/schema.rb")

# set up the fixtures location
Test::Unit::TestCase.fixture_path = File.dirname(__FILE__)  + "/fixtures/"
Test::Unit::TestCase.use_transactional_fixtures = false
Test::Unit::TestCase.use_instantiated_fixtures = false

$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
