require_relative '../../minitest_helper'
require 'cinebase/vista'
require 'base64'

class FakeGuestToken
  class << self
    attr_accessor :tokens, :curls
  end

  def initialize(curl: nil)
    self.class.curls << curl
  end

  def fetch
    self.class.tokens.shift
  end
end

module ExampleChain
  extend Cinebase::Vista::TokenHolder

  def self.guest_token_class
    FakeGuestToken
  end
end

class VistaTokenHolderTest < Minitest::Test
  def setup
    ExampleChain.token = nil
    FakeGuestToken.tokens = []
    FakeGuestToken.curls = []
  end

  def test_token_is_settable
    ExampleChain.token = 'raw-jwt'

    assert_equal('raw-jwt', ExampleChain.token)
  end

  def test_acquire_token_always_fetches
    ExampleChain.token = token_expiring_at(Time.now + 86_400)
    fresh = queue_token(Time.now + 86_400)

    assert_equal(fresh, ExampleChain.acquire_token!(curl: '/bin/curl-impersonate'))
    assert_equal(fresh, ExampleChain.token)
    assert_equal(['/bin/curl-impersonate'], FakeGuestToken.curls)
  end

  def test_token_expires_at_reads_exp_claim
    expires_at = Time.at(Time.now.to_i + 7200)
    ExampleChain.token = token_expiring_at(expires_at)

    assert_equal(expires_at, ExampleChain.token_expires_at)
  end

  def test_token_expires_at_is_nil_without_token
    assert_nil(ExampleChain.token_expires_at)
  end

  def test_token_expires_at_is_nil_for_unreadable_token
    ['not-a-jwt', 'header.e30.signature', 'header.!!!.signature'].each do |token|
      ExampleChain.token = token

      assert_nil(ExampleChain.token_expires_at, token)
    end
  end

  def test_ensure_token_fetches_without_token
    fresh = queue_token(Time.now + 86_400)

    assert_equal(fresh, ExampleChain.ensure_token!(curl: '/bin/curl-impersonate'))
    assert_equal(fresh, ExampleChain.token)
    assert_equal(['/bin/curl-impersonate'], FakeGuestToken.curls)
  end

  def test_ensure_token_reuses_token_outside_renewal_margin
    current = token_expiring_at(Time.now + Cinebase::Vista::TokenHolder::RENEWAL_MARGIN + 60)
    ExampleChain.token = current

    assert_equal(current, ExampleChain.ensure_token!)
    assert_empty(FakeGuestToken.curls)
  end

  def test_ensure_token_renews_token_inside_renewal_margin
    ExampleChain.token = token_expiring_at(Time.now + Cinebase::Vista::TokenHolder::RENEWAL_MARGIN - 60)
    fresh = queue_token(Time.now + 86_400)

    assert_equal(fresh, ExampleChain.ensure_token!)
  end

  def test_ensure_token_renews_unreadable_token
    ExampleChain.token = 'not-a-jwt'
    fresh = queue_token(Time.now + 86_400)

    assert_equal(fresh, ExampleChain.ensure_token!)
  end

  def test_ensure_token_fetches_after_rejection
    rejected = token_expiring_at(Time.now + 86_400)
    ExampleChain.token = rejected
    fresh = queue_token(Time.now + 86_400)

    ExampleChain.reject_token!(rejected)

    assert_nil(ExampleChain.token)
    assert_equal(fresh, ExampleChain.ensure_token!)
  end

  def test_reject_token_defaults_to_current_token
    ExampleChain.token = token_expiring_at(Time.now + 86_400)

    ExampleChain.reject_token!

    assert_nil(ExampleChain.token)
  end

  def test_reject_token_keeps_a_newer_token
    newer = token_expiring_at(Time.now + 86_400)
    ExampleChain.token = newer

    ExampleChain.reject_token!('older-token')

    assert_equal(newer, ExampleChain.token)
  end

  def test_guest_token_class_must_be_defined
    chain = Module.new { extend Cinebase::Vista::TokenHolder }

    assert_raises(NotImplementedError) { chain.acquire_token! }
  end

  private

  def queue_token(expires_at)
    token_expiring_at(expires_at).tap { |token| FakeGuestToken.tokens << token }
  end

  def token_expiring_at(time)
    payload = Base64.urlsafe_encode64(JSON.generate('exp' => time.to_i), padding: false)
    "header.#{payload}.signature"
  end
end
