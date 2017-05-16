require 'rails_helper'

RSpec.describe KitchenSinkMailer, type: :mailer do
  subject { described_class.show.deliver_now }
  it 'successfully sends the email' do
    expect{ subject }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end
end
