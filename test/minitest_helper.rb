require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'cinebase'

require 'minitest/autorun'
require 'minitest/reporters'
options = { color: true, slow_count: 5 }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(options)]
