require_relative '../../minitest_helper'
require 'cinebase/vista'
require 'base64'
require 'fileutils'
require 'tmpdir'

class ExampleGuestToken < Cinebase::Vista::GuestToken
  PAGE_URL = 'https://www.example.com/'.freeze

  private

  def extract_token(html)
    html[/token=(\S+)/, 1]
  end
end

class LenientGuestToken < ExampleGuestToken
  private

  def accepted_statuses
    %w[200 404]
  end
end

class VistaGuestTokenTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir('vista-guest-token')
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_fetch_returns_extracted_token
    token = token_expiring_at(Time.now + 3600)

    assert_equal(token, ExampleGuestToken.new(curl: fake_curl("token=#{token}\n200")).fetch)
  end

  def test_fetch_rejects_expired_token
    curl = fake_curl("token=#{token_expiring_at(Time.now - 60)}\n200")

    assert_raises(Cinebase::Vista::AuthenticationError) { ExampleGuestToken.new(curl: curl).fetch }
  end

  def test_fetch_rejects_page_without_token
    curl = fake_curl("<html></html>\n200")

    assert_raises(Cinebase::Vista::AuthenticationError) { ExampleGuestToken.new(curl: curl).fetch }
  end

  def test_fetch_rejects_malformed_token
    curl = fake_curl("token=not-a-jwt\n200")

    assert_raises(Cinebase::Vista::AuthenticationError) { ExampleGuestToken.new(curl: curl).fetch }
  end

  def test_fetch_rejects_unaccepted_status
    curl = fake_curl("token=#{token_expiring_at(Time.now + 3600)}\n404")

    assert_raises(Cinebase::Vista::AuthenticationError) { ExampleGuestToken.new(curl: curl).fetch }
  end

  def test_subclass_can_accept_other_statuses
    token = token_expiring_at(Time.now + 3600)

    assert_equal(token, LenientGuestToken.new(curl: fake_curl("token=#{token}\n404")).fetch)
  end

  def test_fetch_rejects_failed_command
    curl = fake_curl('', exit_status: 7)

    assert_raises(Cinebase::Vista::AuthenticationError) { ExampleGuestToken.new(curl: curl).fetch }
  end

  def test_fetch_explains_missing_executable
    error = assert_raises(Cinebase::Vista::AuthenticationError) do
      ExampleGuestToken.new(curl: File.join(@directory, 'missing')).fetch
    end
    assert_match(/curl-impersonate/, error.message)
  end

  def test_defaults_to_curl_impersonate_on_path
    token = token_expiring_at(Time.now + 3600)
    fake_curl("token=#{token}\n200")

    with_path(@directory) do
      assert_equal(token, ExampleGuestToken.new.fetch)
    end
  end

  private

  def token_expiring_at(time)
    payload = Base64.urlsafe_encode64(JSON.generate('exp' => time.to_i), padding: false)
    "header.#{payload}.signature"
  end

  def fake_curl(output, exit_status: 0)
    path = File.join(@directory, 'curl-impersonate')
    File.write(path, "#!#{RbConfig.ruby}\nSTDOUT.write(#{output.dump})\nexit #{exit_status}\n")
    File.chmod(0o755, path)
    path
  end

  def with_path(directory)
    original = ENV['PATH']
    ENV['PATH'] = "#{directory}#{File::PATH_SEPARATOR}#{original}"
    yield
  ensure
    ENV['PATH'] = original
  end
end
