require "active_model/email_confirmation/version"
require "active_model/email_confirmation/error"
require "active_model"

module ActiveModel
  class EmailConfirmation
    include Model

    attr_reader :email
    attr_writer :user

    validates :email, presence: true
    validate :existence, if: -> { email.present? }
    delegate :id, to: :user, prefix: true, allow_nil: true

    def email=(email)
      remove_instance_variable(:@user) if defined?(@user)
      @email = email
    end

    def user
      return @user if defined?(@user)
      @user = User.find_by(email: email)
    end

    def token
      self.class.generate_token(user.email)
    end

    def self.find(token)
      email = verify_token(token)
      new(email: email).tap { |email_confirmation| raise EmailInvalid if email_confirmation.invalid? }
    end

    private

    def self.message_verifier
      Rails.application.message_verifier("email confirmation salt")
    end

    def self.generate_token(*args)
      Base64.urlsafe_encode64(message_verifier.generate(*args))
    end

    def self.verify_token(string)
      message_verifier.verify(Base64.urlsafe_decode64(string))
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
      raise TokenInvalid
    end

    def existence
      errors.add(:email, :invalid) if user.blank?
    end
  end
end
