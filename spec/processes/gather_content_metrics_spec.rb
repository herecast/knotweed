require 'spec_helper'

RSpec.describe GatherContentMetrics do
  context 'for an Organization' do
    let(:org) { FactoryGirl.create :organization }
    let(:start_date) { Date.today - 7.days }
    let(:end_date) { Date.today }

    subject { GatherContentMetrics.call(
      owner: org,
      start_date: start_date,
      end_date: end_date
    )}

    describe 'call' do

      describe 'promo_click_thru_count' do
        let!(:content1) { FactoryGirl.create :content,
          pubdate: 2.days.ago, banner_click_count: rand(10),
          organization: org }
        let!(:content2) { FactoryGirl.create :content,
          pubdate: 2.days.ago, banner_click_count: rand(10),
          organization: org }
        let!(:content3) { FactoryGirl.create :content,
          pubdate: 2.weeks.ago, banner_click_count: rand(10),
          organization: org }

        it 'should return the sum of the organization\'s contents `banner_click_count`' do
          expect(subject[:promo_click_thru_count]).to eq(content1.banner_click_count + content2.banner_click_count)
        end
      end

      describe 'view_count' do
        let!(:content1) { FactoryGirl.create :content,
          pubdate: 2.days.ago, view_count: rand(10),
          organization: org }
        let!(:content2) { FactoryGirl.create :content,
          pubdate: 2.days.ago, view_count: rand(10),
          organization: org }
        let!(:content3) { FactoryGirl.create :content,
          pubdate: 2.weeks.ago, view_count: rand(10),
          organization: org }

        it 'should return the sum of the organization\'s contents `view_count`' do
          expect(subject[:view_count]).to eq(content1.view_count + content2.view_count)
        end
      end

      describe 'comment_count' do
        let!(:content1) { FactoryGirl.create :content,
          pubdate: 2.days.ago, comment_count: rand(10),
          organization: org }
        let!(:content2) { FactoryGirl.create :content,
          pubdate: 2.days.ago, comment_count: rand(10),
          organization: org }
        let!(:content3) { FactoryGirl.create :content,
          pubdate: 2.weeks.ago, comment_count: rand(10),
          organization: org }

        it 'should return the sum of the organization\'s contents `comment_count`' do
          expect(subject[:comment_count]).to eq(content1.comment_count + content2.comment_count)
        end
      end

      describe 'daily_view_counts' do
        let!(:content1) { FactoryGirl.create :content, pubdate: 3.days.ago, organization: org }
        let!(:content2) { FactoryGirl.create :content, pubdate: 4.days.ago, organization: org }
        let!(:content_report1) { FactoryGirl.create :content_report, content: content1,
          view_count: rand(10), report_date: 2.days.ago }
        let!(:content_report2) { FactoryGirl.create :content_report, content: content2,
          view_count: rand(10), report_date: content_report1.report_date }

        subject { GatherContentMetrics.call(
          owner: org,
          start_date: start_date,
          end_date: end_date
        )[:daily_view_counts]}

        it 'should sum multiple view counts for a given day' do
          expect(subject.select{ |cr| cr[:report_date].to_date == content_report1.report_date.to_date }.first[:view_count]).to eq(content_report1.view_count + content_report2.view_count)
        end

        it 'should return 0 for days with no views' do
          expect(subject.select{ |cr| cr[:report_date].to_date == 1.day.ago.to_date}.first[:view_count]).to eq 0
        end
      end

      describe 'daily_promo_click_thru_counts' do
        let!(:content1) { FactoryGirl.create :content, pubdate: 3.days.ago, organization: org }
        let!(:content2) { FactoryGirl.create :content, pubdate: 4.days.ago, organization: org }
        let!(:content_report1) { FactoryGirl.create :content_report, content: content1,
          banner_click_count: rand(10), report_date: 2.days.ago }
        let!(:content_report2) { FactoryGirl.create :content_report, content: content2,
          banner_click_count: rand(10), report_date: content_report1.report_date }

        subject { GatherContentMetrics.call(
          owner: org,
          start_date: start_date,
          end_date: end_date
        )[:daily_promo_click_thru_counts]}

        it 'should sum multiple view counts for a given day' do
          expect(subject.select{ |cr| cr[:report_date].to_date == content_report1.report_date.to_date }.first[:banner_click_count]).to eq(content_report1.banner_click_count + content_report2.banner_click_count)
        end
      end

    end
  end

  context 'for a User' do
    let(:user) { FactoryGirl.create :user }
    let(:start_date) { Date.today - 7.days }
    let(:end_date) { Date.today }

    subject { GatherContentMetrics.call(
      owner: user,
      start_date: start_date,
      end_date: end_date
    )}

    describe 'call' do
      describe 'promo_click_thru_count' do
        let!(:content1) { FactoryGirl.create :content,
          pubdate: 2.days.ago, banner_click_count: rand(10),
          created_by: user }
        let!(:content2) { FactoryGirl.create :content,
          pubdate: 2.days.ago, banner_click_count: rand(10),
          created_by: user }
        let!(:content3) { FactoryGirl.create :content,
          pubdate: 2.weeks.ago, banner_click_count: rand(10),
          created_by: FactoryGirl.create(:user) }

        it 'should return the sum of the user\'s contents `banner_click_count`' do
          expect(subject[:promo_click_thru_count]).to eq(content1.banner_click_count + content2.banner_click_count)
        end
      end
    end
  end

end
