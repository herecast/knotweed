class StreamlinedRegistrationMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    StreamlinedRegistrationMailer.confirmation_instructions(User.last, "faketoken", {password: "fakepassword"})
  end
end
