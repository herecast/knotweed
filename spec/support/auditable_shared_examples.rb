# define tests for models that use the Auditable concern (app/models/concerns/auditable.rb)
# Should be included in the relevant models using:
#   include_examples 'Auditable', Content
# where the parameter is the relevant model you're testing.
shared_examples 'Auditable' do |model|
  before do
    @user = FactoryGirl.create :admin
    # not testing sign in here, just signing assignment of properties
    User.current = @user
  end
  
  let(:model_symbol) { model.to_s.underscore }

  describe 'updated_by' do
    before do
      @existing_object = FactoryGirl.create model_symbol
      # updated_by will automatically have been set here, so we need to bypass
      # our before_save callback and set it to nil.
      @existing_object.update_attribute :updated_by, nil
    end

    it "should set updated_by when #{model.to_s} is updated" do
      @existing_object.save
      expect(@existing_object.reload.updated_by).to eq(@user)
    end
  end

  describe 'created_by' do
    it "should set updated and created by when a #{model.to_s} is created" do
      obj = FactoryGirl.create model_symbol, created_by: nil
      expect(obj.created_by).to eq(@user)
      expect(obj.updated_by).to eq(@user)
    end
  end

end
