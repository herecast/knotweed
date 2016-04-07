require "spec_helper"

describe ModerationMailer, :type => :mailer do
  describe "moderation_mailer email" do
    before do
      @content = FactoryGirl.create(:content)
      @content.authoremail = @content.authors + '@example.com'
      @content.save
      @flagging_user = FactoryGirl.create(:user)
      @flagger_name = 'Joseph'
      @flagger_email = 'jos@example.com'
      @params = {:classification => 'Offensive', :flagger_name => @flagger_name, :flagger_email => @flagger_email }
      @subject ='dailyUV Flagged as ' + @params[:classification] + ': ' +  @content.title
    end

    describe 'moderation email' do

      it "should send an email" do
        email = ModerationMailer.send_moderation_flag(@content, @params, @subject).deliver
        expect(ModerationMailer.deliveries.present?).to eq(true)
        expect(email.body.include?(@flagger_name)).to eq(true)
        expect(email.body.include?(@flagger_email)).to eq(true)
        expect(email.body.include?(@content.authors)).to eq(true)
        expect(email.body.include?(@content.authoremail)).to eq(true)
        expect(email.to[0]).to eq(ModerationMailer::MODERATION_EMAIL_RECIPIENT)
      end

      it "generates the proper content type edit link" do
        # regular content
        email = ModerationMailer.send_moderation_flag(@content, @params, @subject).deliver
        url = edit_content_url(@content)
        email.body.include?(url)

        # market content
        @content.channel = FactoryGirl.create(:market_post)
        email = ModerationMailer.send_moderation_flag(@content, @params, @subject).deliver
        url = edit_market_post_url(@content.channel_id)
        email.body.include?(url)

        # event content
        @content.channel = FactoryGirl.create(:event)
        email = ModerationMailer.send_moderation_flag(@content, @params, @subject).deliver
        url = edit_event_url(@content.channel_id)
        email.body.include?(url)
      end
    end

    describe 'version 2' do

      it "should send an email" do
        email = ModerationMailer.send_moderation_flag_v2(@content, @params[:classification], @flagging_user).deliver
        expect(ModerationMailer.deliveries.present?).to eq(true)
        expect(email.body.include?(@flagging_user.name)).to eq(true)
        expect(email.body.include?(@flagging_user.email)).to eq(true)
        expect(email.body.include?(@content.authors)).to eq(true)
        expect(email.body.include?(@content.authoremail)).to eq(true)
        expect(email.to[0]).to eq(ModerationMailer::MODERATION_EMAIL_RECIPIENT)
      end

      it "generates the proper content type edit link" do
        # regular content
        email = ModerationMailer.send_moderation_flag_v2(@content, @params[:classification], @flagging_user).deliver
        url = edit_content_url(@content)
        email.body.include?(url)

        # market content
        @content.channel = FactoryGirl.create(:market_post)
        email = ModerationMailer.send_moderation_flag_v2(@content, @params[:classification], @flagging_user).deliver
        url = edit_market_post_url(@content.channel_id)
        email.body.include?(url)

        # event content
        @content.channel = FactoryGirl.create(:event)
        email = ModerationMailer.send_moderation_flag_v2(@content, @params[:classification], @flagging_user).deliver
        url = edit_event_url(@content.channel_id)
        email.body.include?(url)
      end
    end
  end
end
