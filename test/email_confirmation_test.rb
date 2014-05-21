require "test_helper"

class User
  attr_accessor :id, :email

  RECORDS = {
    {email: "alice@example.com"} => {id: 1, email: "alice@example.com"}
  }

  def self.find_by(options)
    attributes = RECORDS[options]
    new(attributes) if attributes.present?
  end

  def initialize(options)
    self.id              = options[:id]
    self.email           = options[:email]
  end
end

module ActiveModel
  def EmailConfirmation.message_verifier
    key_generator = ActiveSupport::KeyGenerator.new("12345678901234567890123456789012345678901234567890123456789012345678901234567890", iterations: 1000)
    secret = key_generator.generate_key("email confirmation salt")
    ActiveSupport::MessageVerifier.new(secret)
  end
end

class EmailConfirmationTest < Test::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = @email_confirmation = ActiveModel::EmailConfirmation.new
  end

  def test_basic_workflow
    @email_confirmation.email = "alice@example.com"
    @email_confirmation.valid?
    token = @email_confirmation.token
    assert token.present?
    assert !token.include?("/")
    email_confirmation = ActiveModel::EmailConfirmation.find(token)
    assert_equal @email_confirmation.email, email_confirmation.email
    assert email_confirmation.user.present?
  end

  def test_is_invalid_with_invalid_email
    @email_confirmation.email = "invalid@example.com"
    assert @email_confirmation.invalid?
    assert @email_confirmation.errors[:email].present?
  end

  def test_is_invalid_without_email
    @email_confirmation.email = nil
    assert @email_confirmation.invalid?
    assert @email_confirmation.errors[:email].present?
  end

  def test_find_raises_exception_with_invalid_email
    token = ActiveModel::EmailConfirmation.generate_token("invalid@example.com")
    assert_raises(ActiveModel::EmailConfirmation::EmailInvalid) { ActiveModel::EmailConfirmation.find(token) }
  end

  def test_find_raises_exception_with_invalid_token
    assert_raises(ActiveModel::EmailConfirmation::TokenInvalid) { ActiveModel::EmailConfirmation.find("invalidtoken") }
  end

  def test_find_raises_exception_with_non_base64_token
    assert_raises(ActiveModel::EmailConfirmation::TokenInvalid) { ActiveModel::EmailConfirmation.find("%%%%%%%%%") }
  end
end
