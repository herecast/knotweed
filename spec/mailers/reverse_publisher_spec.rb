require "spec_helper"

describe ReversePublisher, :type => :mailer do
  before do
    @news_cat = FactoryGirl.create :content_category, name: 'news'
    @content = FactoryGirl.create :content, authoremail: 'test@test.com', 
      content_category: @news_cat
    @listserv = FactoryGirl.create :listserv
  end

  describe 'after_create PromotionListserv object' do
    before do
      PromotionListserv.create_from_content(@content, @listserv)
      ReversePublisher.deliveries.each do |eml|
        # reverse publish email has this header set, confirmation email does not.
        if eml['X-Original-Content-Id'].present?
          @rp_email = eml
        else
          @conf_email = eml
        end
      end
    end

    it 'should send a confirmation email to the user' do
      expect(ReversePublisher.deliveries.count).to eq(2)
      expect(@conf_email.to).to include(@content.authoremail)
    end

    it 'should send the reverse publish email to the listserv' do
      expect(ReversePublisher.deliveries.count).to eq(2)
      expect(@rp_email.to).to include(@listserv.reverse_publish_email)
    end
  end

  describe 'when sending to multiple listservs' do
    before do
      @listserv2 = FactoryGirl.create :listserv
      PromotionListserv.create_multiple_from_content(@content, [@listserv.id, @listserv2.id])
      @rp_email = ReversePublisher.deliveries.select{ |eml| eml['X-Original-Content-Id'].present? }.first
    end

    it 'should only generate one reverse publish email' do
      expect(ReversePublisher.deliveries.count).to eq(2)
      expect(@rp_email.to).to include(@listserv.reverse_publish_email)
      expect(@rp_email.to).to include(@listserv2.reverse_publish_email)
    end
  end

  # this is testing the special construction of the consumer app URL 
  # for the content based on whether or not Thread.current[:consumer_app] is set
  describe 'ux2 content links' do
    let(:consumer_app) {FactoryGirl.create(:consumer_app)}

    it 'should include the ux2 content path for @content' do
      Thread.new do
        Thread.current[:consumer_app] = FactoryGirl.create(:consumer_app)
        listserv.send_content_to_listserv(@content, consumer_app)
        # only the reverse publish email has this header, so use that to select it
        rp_email = ReversePublisher.deliveries.select{ |e| e['X-Original-Content-Id'].present? }.first
        expect(rp_email.body.encoded).to include("#{consumer_app.uri}/news/#{@content.id}")
      end
    end
  end

end
