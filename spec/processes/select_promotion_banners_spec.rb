require 'spec_helper'

RSpec.describe SelectPromotionBanners do

  describe 'call' do
    let(:repo) { FactoryGirl.build :repository }

    context "when promotion_id passed in" do
      before do
        @promotion_banner = FactoryGirl.create :promotion_banner
        @promotion = FactoryGirl.create :promotion, promotable: @promotion_banner
      end

      subject do
        SelectPromotionBanners.call(
          promotion_id: @promotion.id,
          repository:   repo
        )
      end

      it "returns promotion_banner related to promotion" do
        results = subject
        expect(results.first.promotion_banner).to eq @promotion_banner
      end
    end

    context "when content_id passed in" do
      let(:content) { FactoryGirl.create(:content) }

      subject do
        SelectPromotionBanners.call(
          content_id: content.id,
          repository: repo
        )
      end

      context 'when #banner_ad_override present' do
        let(:override_banner) { FactoryGirl.create(:promotion_banner, :active, :sponsored) }
        let(:content) { FactoryGirl.create :content, banner_ad_override: override_banner.promotion.id }

        it 'returns promo override\'s banner' do
          results = subject
          expect(results.first.promotion_banner).to eql override_banner
        end

        it 'does not query SPARQL::Client' do
          expect_any_instance_of(SPARQL::Client).to_not receive(:query)
          subject
        end
      end

      context 'when content.organization has banner ad override' do
        let(:banner_ad1) { FactoryGirl.create :promotion_banner, :active, :sponsored }
        let(:organization) { FactoryGirl.create :organization, banner_ad_override: "#{banner_ad1.promotion.id}" }
        let!(:content) { FactoryGirl.create :content, organization: organization }

        it 'does not query SPARQL::Client' do
          expect_any_instance_of(SPARQL::Client).to_not receive(:query)
          subject
        end

        it 'returns a banner from the csv override property' do
          expect(subject.first.promotion_banner).to eq banner_ad1
        end

        context 'that is inactive' do
          before do
            @inactive_banner = FactoryGirl.create :promotion_banner, :inactive, :sponsored
            content.organization.update banner_ad_override: @inactive_banner.id
            allow(DspService).to receive(:get_related_promo_ids).and_return []
          end

          it 'not respond with that banner' do
            expect(subject.map(&:promotion_banner)).to_not include @inactive_banner
          end
        end

        context "when banner_ad_override does not return an active ad" do
          before do
            content.organization.update_attribute :banner_ad_override, 1234
            allow(DspService).to receive(:get_related_promo_ids).and_return []
          end

          it "it makes call to DspService for ad" do
            expect(DspService).to receive(:get_related_promo_ids)
            subject
          end
        end
      end

      context 'when SPARQL will return results based on similarity' do
        let(:score) { "9" }
        let(:promo_banner) { FactoryGirl.create :promotion_banner, content: content }

        before do
          mock_data = {
              'score' => score,
              'id' => "#{content.id}"
          }
          allow(DspService).to receive(:get_related_promo_ids).and_return([mock_data])
        end

        context 'and promotion banner has inventory' do
          before do
            promo_banner.update_attributes({
              max_impressions: nil,
              daily_max_impressions: nil
            })
          end

          it 'will return results for one of the promotion banners' do
            results = subject
            expect(results.first.promotion_banner).to eql promo_banner
            expect(results.first.select_score).to eql score
            expect(results.first.select_method).to eql 'relevance'
          end
        end
      end

      context 'When banner does not have inventory' do
        let(:promo_banner) { FactoryGirl.create :promotion_banner, content: content,
          max_impressions: 10, impression_count: 10 }

        context 'when sparql does not return anything' do
          before do
            allow(DspService).to receive(:get_related_promo_ids).and_return([])
          end

          context 'when no paid banners exist' do
            before do
              Promotion.update_all(paid: false)
            end

            context 'when banner is not active' do
              before do
                promo_banner.update_attributes({
                  campaign_start: 1.month.ago,
                  campaign_end: 1.week.ago,
                  max_impressions: nil
                })
                promo_banner.promotion.update_attribute(:content_id, content.id)
              end

              it 'does not return the banner' do
                results = subject
                expect(results.first).to be nil
              end

              it 'does not return banner even with content id' do
                allow(DspService).to receive(:query_promo_similarity_index).and_return([promo_banner.promotion])
                results = subject
                expect(results.first).to be nil
              end
            end
          end
        end
      end
    end

    context "when organization_id passed in" do
      before do
        @org_banner = FactoryGirl.create :promotion_banner
        promotion = FactoryGirl.create :promotion, promotable_id: @org_banner.id, promotable_type: 'PromotionBanner'
        @organization = FactoryGirl.create :organization, banner_ad_override: promotion.id
      end

      subject do
        SelectPromotionBanners.call(
          organization_id: @organization.id,
          repository: repo
        )
      end

      it "returns promoted banner" do
        results = subject
        expect(results.first.id).to eq @org_banner.id
      end
    end

    context "when no reference provided" do
      subject { SelectPromotionBanners.call(repository: repo) }

      context 'when an active and boosted NON-RUN-OF-SITE promotion exists' do
        let!(:sponsored_banner) { FactoryGirl.create :promotion_banner, :active, :sponsored, boost: true, max_impressions: nil }

        it 'does not return the banner' do
          expect(subject).to_not include(sponsored_banner)
        end
      end

      context "when coupon exists" do
        before do
          @promotion_banner = FactoryGirl.create :promotion_banner,
            promotion_type: PromotionBanner::COUPON,
            coupon_image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
        end

        it "returns coupon" do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
        end
      end

      context "when active and boosted promotion exists" do
        before do
          @promotion_banner = FactoryGirl.create :promotion_banner, boost: true, max_impressions: nil
        end

        it "gets a random boosted promotion banner" do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
        end
      end

      context "when no boosted promotions exist" do
        before do
          @promotion_banner = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.tomorrow
        end

        it "gets a random active with inventory promotion banner" do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
        end
      end

      context "when only active with no inventory" do
        let!(:banner) { FactoryGirl.create :promotion_banner, :active, daily_max_impressions: 5, daily_impression_count: 6 }

        it "gets active, no inventory ad" do
          expect(subject.first.promotion_banner).to eq banner
        end
      end

      context 'when only active, no inventory, and non-ROS' do
        let!(:banner) do
          FactoryGirl.create :promotion_banner, :active, :digest,
            daily_max_impressions: 5, daily_impression_count: 6
        end

        it 'should return nothing' do
          expect(subject).to eq []
        end
      end
    end

    context "when context and limit passed in" do
      before do
        @promotion_banner1 = FactoryGirl.create :promotion_banner
        @promotion_banner2 = FactoryGirl.create :promotion_banner, boost: true, max_impressions: nil
        @promotion_banner3 = FactoryGirl.create :promotion_banner, daily_max_impressions: 5, daily_impression_count: 6
        @promotion_banner4 = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.tomorrow
        @promotion_banner5 = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.yesterday
        @promotion = FactoryGirl.create :promotion, promotable: @promotion_banner1
      end

      subject do
        SelectPromotionBanners.call(
          limit: "4",
          repository: repo
        )
      end

      it "returns the specified number of promotion banners" do
        results = subject
        expect(results.length).to eq 4
        expect(results.map{ |r| r.promotion_banner.id}).to_not include(@promotion_banner5.id)
      end
    end

    context "when exclude passed in" do
      before do
        @promotion_banner = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.tomorrow
      end

      subject do
        SelectPromotionBanners.call(
          exclude: [@promotion_banner.id],
          repository: repo
        )
      end

      it "does not return excluded promotion banners" do
        results = subject
        expect(results).to eq []
      end
    end

    context 'when feature flag is specifying an override' do
      let!(:other_promos) {
        FactoryGirl.create :promotion,
          promotable: FactoryGirl.create(:promotion_banner)
      }
      let!(:promo) {
        FactoryGirl.create :promotion,
          promotable: FactoryGirl.create(:promotion_banner)
      }
      before do
        Feature.create(
          active: true,
          name: 'global-banner-override',
          options: "[#{promo.id}]"
        )
      end

      subject do
        SelectPromotionBanners.call()
      end

      it 'returns the banner for the promo override' do
        expect(subject.first.promotion_banner).to eql promo.promotable
      end

      describe 'when multiple are asked for' do
        let(:limit) { 5 }
        subject do
          SelectPromotionBanners.call(limit: limit)
        end

        it 'returns the same banner x times' do
          expect(subject.count).to eql limit
          subject.each do |result|
            expect(result.promotion_banner).to eql promo.promotable
          end
        end
      end
    end
  end

end
