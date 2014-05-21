module ActiveModel
  class EmailConfirmation
    class Error < StandardError; end
    class EmailInvalid < Error; end
    class TokenInvalid < Error; end
  end
end
