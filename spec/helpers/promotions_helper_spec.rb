require 'spec_helper' 

describe PromotionsHelper, type: :helper do
  describe '#get_promotions_list' do
    context "Given organization, and content" do
      it 'returns content#promotions' do
        content = Content.new
        organization = Organization.new

        expect(content).to receive(:promotions).and_return(:content_promotions)
        expect(organization).to_not receive(:promotions)

        expect( helper.get_promotion_list(organization, content) ).to eql :content_promotions
      end
    end

    context 'Given organization, and nil content' do
      it 'returns content#promotions' do
        content = nil
        organization = Organization.new

        expect(organization).to receive(:promotions).and_return(:organization_promotions)

        expect( helper.get_promotion_list(organization, content) ).to eql :organization_promotions
      end
    end
  end
end
