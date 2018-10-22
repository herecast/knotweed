require 'spec_helper'

describe Api::V3::ImagesController, :type => :controller do
  before do
    @market_post = FactoryGirl.create :market_post
    @file1 = fixture_file_upload('/photo.jpg', 'image/jpg')
    @user = FactoryGirl.create :user # some other user
    api_authenticate user: @user
  end

  describe 'POST create' do
    subject { post :create, params: { image: { image: @file1, primary: false,
              content_id: @market_post.content.id } } }

    context 'as signed in user with authorization' do
      before do
        @market_post.content.update_attribute :created_by, @user
      end


      it 'should create an image' do
        expect{subject}.to change{Image.count}.by 1
      end

      it 'should add an image to the content in question' do
        expect{subject}.to change{@market_post.content.images.count}.by 1
      end
    end

    context 'without authorization' do
      before do
        @market_post.content.update_attribute :created_by, nil
      end

      it 'should not create an image' do
        expect{subject}.to_not change{Image.count}
      end

      it 'should respond with 403' do
        subject
        expect(response.code).to eq('403')
      end
    end

    context "when image does not save" do
      before do
        @market_post.content.update_attribute :created_by, @user
        allow_any_instance_of(Image).to receive(:save).and_return(false)
      end

      subject { post :create, params: { image: { image: @file1, content_id: @market_post.content.id } } }

      it "returns unprocessable entity status" do
        subject
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe 'POST upsert' do
    let(:content) { FactoryGirl.create :content, :talk }

    subject { post :upsert, params: { image: { image: @file1, primary: false,
              content_id: content.id } } }

    context 'as signed in user with authorization' do
      before do
        content.update_attribute :created_by, @user
      end


      it 'should create an image' do
        expect{subject}.to change{Image.count}.by 1
      end

      it 'should add an image to the content in question' do
        expect{subject}.to change{content.images.count}.by 1
      end

      context 'existing images' do
        before do
          content.images = FactoryGirl.create_list(:image, 3, imageable: content)
        end

        it 'should remove the exiting images' do
          subject
          expect(content.images.count).to eql 1
        end
      end
    end

    context 'without authorization' do
      before do
        content.update_attribute :created_by, nil
      end

      it 'should not create an image' do
        expect{subject}.to_not change{Image.count}
      end

      it 'should respond with 403' do
        subject
        expect(response.code).to eq('403')
      end
    end

    context "when image does not save" do
      before do
        content.update_attribute :created_by, @user
        allow_any_instance_of(Image).to receive(:save).and_return(false)
      end

      subject { post :create, params: { image: { image: @file1, content_id: content.id } } }

      it "returns unprocessable entity status" do
        subject
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe 'PUT update' do
    before do
      @content = FactoryGirl.create :content
      @img = FactoryGirl.create :image, primary: false
      # need to have multiple images on the imageable or the first one is set to primary automatically
      @img2 = FactoryGirl.create :image, primary: true
      @market_post.content.images += [@img, @img2]
    end

    subject { put :update, params: { id: @img.id, image: { primary: true, content_id: @content.id } } }

    it 'should update the primary attribute' do
      expect{subject}.to change{@img.reload.primary}.to true
    end

    context 'image caption' do
      let(:caption) { 'my nice caption' }

      subject { put :update, params: { id: @img.id, image: { primary: true, caption: caption, content_id: @content.id } } }
      it 'should update image caption' do
        expect{subject}.to change{@img.reload.caption}.to caption
      end
    end

    context "when update fails" do
      before do
        @market_post.content.update_attribute :created_by, @user
        allow_any_instance_of(Image).to receive(:update_attributes).and_return(false)
      end

      subject { put :update, params: { id: @img.id, image: { primary: true, content_id: @content.id } } }

      it "returns unprocessable entity status" do
        subject
        expect(response).to have_http_status :ok
      end
    end
  end

  describe 'DELETE destroy' do
    before do
      @img = FactoryGirl.create :image
      @market_post.content.images << @img
    end

    subject { delete :destroy, params: { id: @img.id } }

    it 'should remove the image from the associated content' do
      expect{subject}.to change{@market_post.content.images.count}.by -1
    end

    it 'should destroy the image record' do
      expect{subject}.to change{Image.find_by_id(@img.id)}.from(@img).to(nil)
    end
  end
end
