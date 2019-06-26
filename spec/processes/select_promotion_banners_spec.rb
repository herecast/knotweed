# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SelectPromotionBanners do
  describe 'call' do
    context 'when promotion_id passed in' do
      before do
        @promotion_banner = FactoryGirl.create :promotion_banner
        @promotion = FactoryGirl.create :promotion, promotable: @promotion_banner
      end

      subject { SelectPromotionBanners.call(promotion_id: @promotion.id) }

      it 'returns promotion_banner related to promotion' do
        results = subject
        expect(results.first.promotion_banner).to eq @promotion_banner
      end
    end

    context 'when content_id passed in' do
      let(:content) { FactoryGirl.create(:content) }

      subject { SelectPromotionBanners.call(content_id: content.id) }

      context 'when #banner_ad_override present' do
        let(:override_banner) { FactoryGirl.create(:promotion_banner, :active, :sponsored) }
        let(:content) { FactoryGirl.create :content, banner_ad_override: override_banner.promotion.id }

        it 'returns promo override\'s banner' do
          results = subject
          expect(results.first.promotion_banner).to eql override_banner
        end
      end

      context 'when content.organization has banner ad override' do
        let(:banner_ad1) { FactoryGirl.create :promotion_banner, :active, :sponsored }
        let(:organization) { FactoryGirl.create :organization, banner_ad_override: banner_ad1.promotion.id.to_s }
        let!(:content) { FactoryGirl.create :content, organization: organization }

        it 'returns a banner from the csv override property' do
          expect(subject.first.promotion_banner).to eq banner_ad1
        end

        context 'that is inactive' do
          before do
            @inactive_banner = FactoryGirl.create :promotion_banner, :inactive, :sponsored
            content.organization.update banner_ad_override: @inactive_banner.id
          end

          it 'not respond with that banner' do
            expect(subject.map(&:promotion_banner)).to_not include @inactive_banner
          end
        end
      end

      context "when content location has promotion_banner" do
        before do
          @promotion_banner = FactoryGirl.create :promotion_banner,
            location_id: content.location.id,
            promotion_type: 'Targeted'
        end

        it "returns targeted ad connected to content location" do
          expect(subject.map(&:promotion_banner)).to eq [@promotion_banner]
        end
      end

      context 'When banner does not have inventory' do
        let(:promo_banner) do
          FactoryGirl.create :promotion_banner, content: content,
                                                max_impressions: 10, impression_count: 10
        end

        context 'when no paid banners exist' do
          before do
            Promotion.update_all(paid: false)
          end

          context 'when banner is not active' do
            before do
              promo_banner.update_attributes(
                campaign_start: 1.month.ago,
                campaign_end: 1.week.ago,
                max_impressions: nil
              )
              promo_banner.promotion.update_attribute(:content_id, content.id)
            end

            it 'does not return the banner' do
              results = subject
              expect(results.first).to be nil
            end

            it 'does not return banner even with content id' do
              results = subject
              expect(results.first).to be nil
            end
          end
        end
      end
    end

    context 'when organization_id passed in' do
      before do
        @org_banner = FactoryGirl.create :promotion_banner
        promotion = FactoryGirl.create :promotion, promotable_id: @org_banner.id, promotable_type: 'PromotionBanner'
        @organization = FactoryGirl.create :organization, banner_ad_override: promotion.id
      end

      subject { SelectPromotionBanners.call(organization_id: @organization.id) }

      it 'returns promoted banner' do
        results = subject
        expect(results.first.id).to eq @org_banner.id
      end
    end

    context 'when no reference provided' do
      subject { SelectPromotionBanners.call }

      context 'when an active and boosted NON-RUN-OF-SITE promotion exists' do
        let!(:sponsored_banner) { FactoryGirl.create :promotion_banner, :active, :sponsored, boost: true, max_impressions: nil }

        it 'does not return the banner' do
          expect(subject).to_not include(sponsored_banner)
        end
      end

      context 'when coupon exists' do
        before do
          @promotion_banner = FactoryGirl.create :promotion_banner,
                                                 promotion_type: PromotionBanner::COUPON,
                                                 coupon_image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
        end

        it 'returns coupon' do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
        end
      end

      context 'when active and boosted promotion exists' do
        before do
          @promotion_banner = FactoryGirl.create :promotion_banner, boost: true, max_impressions: nil
        end

        it 'gets a random boosted promotion banner' do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
        end
      end

      context 'when no boosted promotions exist' do
        before do
          @promotion_banner = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.tomorrow
        end

        it 'gets a random active with inventory promotion banner' do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
        end
      end

      context 'when only active with no inventory' do
        let!(:banner) { FactoryGirl.create :promotion_banner, :active, daily_max_impressions: 5, daily_impression_count: 6 }

        it 'gets active, no inventory ad' do
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

    context 'when location id passed in' do
      before do
        @location = FactoryGirl.create :location
        @promotion_banner = FactoryGirl.create :promotion_banner,
          promotion_type: PromotionBanner::TARGETED,
          location: @location
        @campaign = FactoryGirl.create :content, :campaign
        @promotion_banner.promotion.update_attribute(
          :content_id, @campaign.id
        )
      end

      let(:opts) { { location_id: @location.id } }

      subject { SelectPromotionBanners.call(opts) }

      context 'when there is ad in same location' do
        it "returns campaign in same location" do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
          expect(results.first.select_method).to eq 'targeted'
        end
      end

      context 'when ad is in location within 50 miles' do
        before do
          @close_location = FactoryGirl.create :location
          @promotion_banner.update_attribute(:location_id, @close_location.id)
          @location.update_attribute(
            :location_ids_within_fifty_miles,
            [@close_location.id]
          )
        end

        it "returns campaign in close location" do
          results = subject
          expect(results.first.promotion_banner).to eq @promotion_banner
          expect(results.first.select_method).to eq 'targeted'
        end
      end
    end

    context 'when context and limit passed in' do
      before do
        @promotion_banner1 = FactoryGirl.create :promotion_banner
        @promotion_banner2 = FactoryGirl.create :promotion_banner, boost: true, max_impressions: nil
        @promotion_banner3 = FactoryGirl.create :promotion_banner, daily_max_impressions: 5, daily_impression_count: 6
        @promotion_banner4 = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.tomorrow
        @promotion_banner5 = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.yesterday
        @promotion = FactoryGirl.create :promotion, promotable: @promotion_banner1
      end

      subject { SelectPromotionBanners.call(limit: '4') }

      it 'returns the specified number of promotion banners' do
        results = subject
        expect(results.length).to eq 4
        expect(results.map { |r| r.promotion_banner.id }).to_not include(@promotion_banner5.id)
      end
    end

    context 'when exclude passed in' do
      before do
        @promotion_banner = FactoryGirl.create :promotion_banner, campaign_start: Date.yesterday, campaign_end: Date.tomorrow
      end

      subject { SelectPromotionBanners.call(exclude: [@promotion_banner.id]) }

      it 'does not return excluded promotion banners' do
        results = subject
        expect(results).to eq []
      end
    end

    context 'when feature flag is specifying an override' do
      let!(:other_promos) do
        FactoryGirl.create :promotion,
                           promotable: FactoryGirl.create(:promotion_banner)
      end
      let!(:promo) do
        FactoryGirl.create :promotion,
                           promotable: FactoryGirl.create(:promotion_banner)
      end
      before do
        Feature.create(
          active: true,
          name: 'global-banner-override',
          options: "[#{promo.id}]"
        )
      end

      subject { SelectPromotionBanners.call }

      it 'returns the banner for the promo override' do
        expect(subject.first.promotion_banner).to eql promo.promotable
      end

      describe 'when multiple are asked for' do
        let(:limit) { 5 }
        subject { SelectPromotionBanners.call(limit: limit) }

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
