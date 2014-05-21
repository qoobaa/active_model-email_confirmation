# ActiveModel::EmailConfirmation

`ActiveModel::EmailConfirmation` is a lightweight email confirmation model implemented on top of `ActiveModel::Model`. It does not require storing any additional information in the database. Resulting token is signed by `ActiveSupport::MessageVerifier` class, using `secret_key_base` and salt.

## Installation

Add this line to your application's Gemfile:

    gem "active_model-email_confirmation"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_model-email_confirmation

## Usage

The most popular workflow is:

    class UsersController < ApplicationController
      def create
        # ...
        @email_confirmation = ActiveModel::EmailConfirmation.new(user: @user)
        UserMailer.confirm_email(@user.email, @email_confirmation.token).deliver
        # ...
      end
    end

    class EmailConfirmationsController < ApplicationController
      def show
        # find raises TokenInvalid, EmailInvalid exceptions
        @email_confirmation = ActiveModel::EmailConfirmation.find(params[:id])
        @user = @email_confirmation.user
        @user.update(confirmed_at: DateTime.now)
        # ...
      rescue ActiveModel::EmailConfirmation::Error
        raise ActiveRecord::RecordNotFound # display 404
      end
    end

If you don't like the default behavior, you can always inherit the model and override some defaults:

    class EmailConfirmation < ActiveModel::EmailConfirmation
      def email=(email)
        @email = email
        @user = Admin.find_by(email: email)
      end
    end

## Copyright

Copyright © 2014 Kuba Kuźma. See LICENSE for details.
