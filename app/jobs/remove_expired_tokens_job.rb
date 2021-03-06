# frozen_string_literal: true

class RemoveExpiredTokensJob < ApplicationJob
  def perform
    SignInToken.clean_stale!
  end
end
