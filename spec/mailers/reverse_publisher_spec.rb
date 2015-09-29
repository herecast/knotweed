require "spec_helper"

describe ReversePublisher do
  before do
    @news_cat = FactoryGirl.create :content_category, name: 'news'
    @content = FactoryGirl.create :content, authoremail: 'test@test.com', 
      content_category: @news_cat
    @listserv = FactoryGirl.create :listserv
  end

  describe 'after_create PromotionListserv object' do
    before do
      PromotionListserv.create_from_content(@content, @listserv)
    end

    it 'should send a confirmation email to the user' do
      ReversePublisher.deliveries.count.should == 2
      # we don't know if conf is first or second so have to iterate through
      should_pass = false
      ReversePublisher.deliveries.each do |eml|
        should_pass = eml.to.include? @content.authoremail
        break if should_pass
      end
      should_pass.should == true
    end

    it 'should send the reverse publish email to the listserv' do
      ReversePublisher.deliveries.count.should == 2
      # we don't know if conf is first or second so have to iterate through
      should_pass = false
      ReversePublisher.deliveries.each do |eml|
        should_pass = eml.to.include? @listserv.reverse_publish_email
        break if should_pass
      end
      should_pass.should == true
    end
  end

  # this is testing the special construction of the consumer app URL 
  # for the content based on whether or not Thread.current[:consumer_app] is set
  describe 'ux2 content links' do
    before do
      # stub out Thread.current for purposes of testing this
      allow(Thread).to receive(:current).and_return({consumer_app: FactoryGirl.create(:consumer_app)})
      @listserv.send_content_to_listserv(@content, Thread.current[:consumer_app])
    end
    it 'should include the ux2 content path for @content' do
      should_pass = false
      ReversePublisher.deliveries.each do |eml|
        should_pass = eml.body.include? "#{Thread.current[:consumer_app].uri}/news/#{@content.id}"
        break if should_pass
      end
      expect(should_pass).to eq(true)
    end
  end

end
