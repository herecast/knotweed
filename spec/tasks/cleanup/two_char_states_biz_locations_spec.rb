require 'rails_helper'

RSpec.describe 'rake cleanup:two_char_states_biz_locations', type: :task do
  before do
    stub_request(:get,
      "https://www.irs.gov:443/pub/irs-soi/14zpallnoagi.csv").
      to_return(
        :status => 200,
        :body => (
          <<~CSV
            STATEFIPS,STATE,ZIPCODE,AGISTUB,N1,MARS1
            1,ID,83854,,,
            1,NH,03033,,,
            1,VT,05031,,,
          CSV
        ).strip,
        :headers => {'Content-Type' => 'text/csv'})
  end

  context 'Business locations exist with non char states' do
    let!(:biz_1) do
      record = FactoryGirl.build :business_location,
        city: "Post Falls",
        state: "Idaho",
        zip: "83854"
      record.save(validate: false)
      record
    end

    let!(:biz_2) do
      record = FactoryGirl.build :business_location,
        city: "Barnard",
        state: "Vermont (VT)",
        zip: "05031"
      record.save(validate: false)
      record
    end

    let!(:biz_3) do
      record = FactoryGirl.build :business_location,
        city: "Brookline",
        state: "nh, new hampshire",
        zip: "03033"
      record.save(validate: false)
      record
    end

    it 'rewrites the states as 2 char abbreviations' do
      task.execute
      expect(biz_1.reload.state).to eq 'ID'
      expect(biz_2.reload.state).to eq 'VT'
      expect(biz_3.reload.state).to eq 'NH'
    end
  end

  context 'Business locations exist, which do not map to zip code' do
    let!(:biz_1) do
      record = FactoryGirl.build :business_location,
        city: "Post Falls",
        state: "Idaho",
        zip: "-"
      record.save(validate: false)
      record
    end

    let!(:biz_2) do
      record = FactoryGirl.build :business_location,
        city: "Barnard",
        state: "Vermont (VT)",
        zip: "99"
      record.save(validate: false)
      record
    end

    it 'outputs a list of ids that failed to update' do
      expect{ task.execute }.to output(
        <<~OUT
          Done, 0 completed
          Failed BusinessLocation records: (2)
          #{biz_1.id}, #{biz_2.id}
        OUT
      ).to_stdout
    end

  end

end
