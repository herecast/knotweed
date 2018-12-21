# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BillDotComService do

  subject { BillDotComService }

  it { is_expected.to respond_to(:authenticate) }
  it { is_expected.to respond_to(:send_payment) }
  it { is_expected.to respond_to(:find_vendor) }
  it { is_expected.to respond_to(:create_bill) }
end
