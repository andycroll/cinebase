require_relative '../../minitest_helper'
require 'cinebase/vista/package_task'

class VistaPackageTaskTest < Minitest::Test
  def setup
    Rake.application = Rake::Application.new
    Cinebase::Vista::PackageTask.new('cinebase.gemspec')
  end

  def teardown
    Rake.application = Rake::Application.new
  end

  def test_defines_native_and_all_tasks
    assert(Rake::Task.task_defined?('package:native'))
    assert(Rake::Task.task_defined?('package:all'))
  end

  def test_native_task_takes_platform
    assert_equal([:platform], Rake::Task['package:native'].arg_names)
  end

  def test_unknown_platform_raises
    assert_raises(KeyError) { Rake::Task['package:native'].invoke('sparc-solaris') }
  end
end
