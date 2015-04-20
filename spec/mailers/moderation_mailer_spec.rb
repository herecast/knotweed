require "spec_helper"

describe ModerationMailer do
  describe "moderation_mailer email" do
    before do
      @content = FactoryGirl.create(:content)
      @content.authoremail = @content.authors + '@example.com'
      @content.save
      @flagger_name = 'Joseph'
      @flagger_email = 'jos@example.com'
      @params = {:classification => 'Offensive', :flagger_name => @flagger_name, :flagger_email => @flagger_email }
      @subject ='dailyUV Flagged as ' + @params[:classification] + ': ' +  @content.title
    end

    it "should send an email" do

      email = ModerationMailer.send_moderation_flag(@content, @params, @subject).deliver
      ModerationMailer.deliveries.present?.should== true
      email.body.include?(@flagger_name).should == true
      email.body.include?(@flagger_email).should == true
      email.body.include?(@content.authors).should == true
      email.body.include?(@content.authoremail).should == true
      email.body.include?(@content.raw_content).should == true
      email.to[0].should == ModerationMailer::MODERATION_EMAIL_RECIPIENT
    end

  end
end
