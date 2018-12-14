# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/kitchen_sink
class KitchenSinkPreview < ActionMailer::Preview
  def kitchen_sink
    KitchenSinkMailer.show
  end
end
