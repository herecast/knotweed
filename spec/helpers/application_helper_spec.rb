require 'spec_helper'

describe ApplicationHelper, type: :helper do
  describe '#display_base_errors' do
    context 'Given a resource with base errors empty' do
      let(:resource) { double(errors: {base: []}) }
      subject { helper.display_base_errors(resource) }

      it { is_expected.to be_blank }
    end

    context 'Given a resource with multiple base errors' do
      let(:errors) { ["error 1", "Error 2"] }
      let(:resource) { double(errors: {
        base: errors
      }) }
      subject { helper.display_base_errors(resource) }
      it 'generates html with all the error messages' do
        expect(subject).to satisfy{|html| errors.all?{|e| html.include?(e)}}
      end
    end
  end

  describe "#link_to_add_field" do
    before do
      @location = FactoryGirl.create :location
      allow_any_instance_of(self.class).to receive(:render).and_return("great fields")
    end
    
    it "builds field" do
      result = form_for(@location, url: '/locations') { |f| link_to_add_fields("Add users", f, :users) }
      expect(result).to include("id=\"edit_location_#{@location.id}\"")
    end
  end
end
