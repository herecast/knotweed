require "spec_helper"

describe ReversePublisher do
  describe 'after_create PromotionListserv object' do
    before do
      @content = FactoryGirl.create :content, authoremail: 'test@test.com'
      @listserv = FactoryGirl.create :listserv
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

end
