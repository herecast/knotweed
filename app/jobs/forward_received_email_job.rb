class ForwardReceivedEmailJob < ApplicationJob
  def perform(received_email, to)
    email = received_email.message_object.dup
    email.to = to
    email.deliver!
  end
end
