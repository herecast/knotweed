require 'rails_helper'

RSpec.describe PaymentReportService do

  describe '#run_report' do
    subject { PaymentReportService.run_report(report, params) }
    
    let(:user) { FactoryGirl.create :user }
    let(:params) { { start_date: 1.week.ago.strftime('%D'), end_date: Date.today.strftime('%D')} }
    let(:report) { PaymentReportService::AVAILABLE_REPORTS[1] }

    context 'without required params' do
      let(:params) { {} }

      it 'should raise an exception' do
        expect{subject}.to raise_error(ArgumentError)
      end
    end

    context 'with an invalid report type' do
      let(:report) { "not a valid report" }

      it 'should raise an exception' do
        expect{subject}.to raise_error(ArgumentError)
      end
    end

    describe 'for publisher_read_payments', freeze_time: true do
      let(:report) { "publisher_read_payments" }
      let(:org) { FactoryGirl.create :organization, pay_for_content: true }
      let(:params) { {
        start_date: 1.week.ago.strftime('%D'),
        end_date: Date.today.strftime('%D'),
        period_ad_rev: 2149.88,
        org_name: org.name,
        user_id: user.id
      } }
      
      it 'should call `publisher_read_payments`' do
        expect(PaymentReportService).to receive(report.to_sym).with(params)
        subject
      end

      context 'with no promotion banner metrics' do
        it 'should return an empty array' do
          expect(subject).to match_array []
        end
      end

      context 'with child organizations with contents' do
        let(:child_org) { FactoryGirl.create :organization, pay_for_content: true, parent: org }
        let(:included_content1) { FactoryGirl.create :content, organization: child_org }
        let!(:promotion_metrics) { FactoryGirl.create_list :promotion_banner_metric, 3,  content: included_content1,
          created_at: 2.days.ago }

        it 'should include that payment' do
          impression_count = promotion_metrics.count
          ppi = (params[:period_ad_rev] / impression_count).to_d.truncate(2)
          expect(subject).to match_array([
            {
              total_payment: (ppi*impression_count).to_d.truncate(2),
              period_start: Date.parse(params[:start_date]),
              period_end: Date.parse(params[:end_date]),
              payment_date: Time.current,
              pay_per_impression: ppi,
              paid_impressions: impression_count,
              content_id: included_content1.id,
              paid_to: user
            }
          ])
        end
      end

      context 'with some organization contents' do
        let(:included_content1) { FactoryGirl.create :content, organization: org }
        let(:included_content2) { FactoryGirl.create :content, organization: org }
        let(:not_included_content1) { FactoryGirl.create :content, created_by: user,
          organization: FactoryGirl.create(:organization) }

        before do
          [included_content1, included_content2, not_included_content1].each do |c|
            FactoryGirl.create :promotion_banner_metric, content: c, created_at: 2.days.ago
          end
        end

        it 'should respond with the correct payments' do
          total_views = PromotionBannerMetric.all.count
          content1_view_count = PromotionBannerMetric.where(content_id: included_content1.id).count
          content2_view_count = PromotionBannerMetric.where(content_id: included_content2.id).count
          pay_per_impression = (params[:period_ad_rev] / total_views).to_d.truncate(2)
          expect(subject).to match_array([
            {
              total_payment: (pay_per_impression * content1_view_count).to_d.truncate(2),
              period_start: Date.parse(params[:start_date]),
              period_end: Date.parse(params[:end_date]),
              payment_date: Time.current,
              pay_per_impression: pay_per_impression,
              paid_impressions: content1_view_count,
              content_id: included_content1.id,
              paid_to: user
            },
            {
              total_payment: (pay_per_impression * content2_view_count).to_d.truncate(2),
              period_start: Date.parse(params[:start_date]),
              period_end: Date.parse(params[:end_date]),
              payment_date: Time.current,
              pay_per_impression: pay_per_impression,
              paid_impressions: content2_view_count,
              content_id: included_content2.id,
              paid_to: user
            }
          ])
        end
      end
    end

    describe 'for blogger_read_payments' do
      let(:report) { "blogger_read_payments" }
      let(:params) { {
        start_date: 1.week.ago.strftime('%D'),
        end_date: Date.today.strftime('%D'),
        period_ad_rev: 2345.67,
        user_id: user.id
      } }
      
      it 'should call `blogger_read_payments`' do
        expect(PaymentReportService).to receive(report.to_sym).with(params)
        subject
      end

      context 'with no promotion banner metrics' do
        it 'should return an empty array' do
          expect(subject).to match_array []
        end
      end

      context 'with one content record matching', freeze_time: true do
        # created by user, has org with `pay_for_content` = true
        let(:org) { FactoryGirl.create :organization, pay_for_content: true }
        let!(:included_content) { FactoryGirl.create :content, created_by: user, organization: org }
        # created by user, has org with `pay_for_content` = false
        let(:org2) { FactoryGirl.create :organization, pay_for_content: false }
        let!(:not_included_content1) { FactoryGirl.create :content, created_by: user, organization: org2 }
        # not created by the user
        let!(:not_included_content2) { FactoryGirl.create :content }

        let(:params) { {
          start_date: 1.week.ago.strftime('%D'),
          end_date: Date.today.strftime('%D'),
          period_ad_rev: 2345.67,
          user_id: user.id
        } }

        before do
          [included_content, not_included_content1, not_included_content2].each do |c|
            FactoryGirl.create :promotion_banner_metric, content: c, created_at: 2.days.ago
          end
        end

        it 'should respond with the correct payment' do
          total_views = PromotionBannerMetric.all.count
          included_view_count = PromotionBannerMetric.where(content: included_content).count
          pay_per_impression = (params[:period_ad_rev] / total_views).to_d.truncate(2)
          expect(subject).to match_array([{
            total_payment: (pay_per_impression * included_view_count).to_d.truncate(2),
            period_start: Date.parse(params[:start_date]),
            period_end: Date.parse(params[:end_date]),
            payment_date: Time.current,
            pay_per_impression: pay_per_impression,
            paid_impressions: included_view_count,
            content_id: included_content.id,
            paid_to: user
          }])
        end

      end

      context 'with multiple content records matching', freeze_time: true do
        # created by user, has org with `pay_for_content` = true
        let(:org) { FactoryGirl.create :organization, pay_for_content: true }
        let!(:included_content1) { FactoryGirl.create :content, created_by: user, organization: org }
        let!(:included_content2) { FactoryGirl.create :content, created_by: user, organization: org }

        let(:params) { {
          start_date: 1.week.ago.strftime('%D'),
          end_date: Date.today.strftime('%D'),
          period_ad_rev: 2345.67,
          user_id: user.id
        } }

        before do
          [included_content1, included_content2].each do |c|
            FactoryGirl.create :promotion_banner_metric, content: c, created_at: 2.days.ago
            FactoryGirl.create :promotion_banner_metric, content: c, created_at: 3.days.ago
          end
        end

        it 'should respond with the correct payments' do
          total_views = PromotionBannerMetric.all.count
          content1_view_count = PromotionBannerMetric.where(content_id: included_content1.id).count
          content2_view_count = PromotionBannerMetric.where(content_id: included_content2.id).count
          pay_per_impression = (params[:period_ad_rev] / total_views).to_d.truncate(2)
          expect(subject).to match_array([
            {
              total_payment: (pay_per_impression * content1_view_count).to_d.truncate(2),
              period_start: Date.parse(params[:start_date]),
              period_end: Date.parse(params[:end_date]),
              payment_date: Time.current,
              pay_per_impression: pay_per_impression,
              paid_impressions: content1_view_count,
              content_id: included_content1.id,
              paid_to: user
            },
            {
              total_payment: (pay_per_impression * content2_view_count).to_d.truncate(2),
              period_start: Date.parse(params[:start_date]),
              period_end: Date.parse(params[:end_date]),
              payment_date: Time.current,
              pay_per_impression: pay_per_impression,
              paid_impressions: content2_view_count,
              content_id: included_content2.id,
              paid_to: user
            }
          ])
        end
      end
    end
  end
end
