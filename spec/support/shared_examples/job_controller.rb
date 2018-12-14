shared_examples_for "JobController" do
  let(:model_class) { subject.controller_name.classify.constantize }

  describe '#run_job' do
    let(:model) { FactoryGirl.create model_class.name.underscore }
    before do
      allow(model_class).to receive(:find).and_return(model)
    end

    it 'assigns @job' do
      get :run_job, xhr: true, params: { id: model.id }, format: :js
      expect(assigns(:job)).to eql model
    end

    it 'renders jobs/run_job' do
      get :run_job, xhr: true, params: { id: model.id }, format: :js
      expect(response).to render_template('jobs/run_job')
    end

    context 'When status is "running"' do
      it 'calls model#enqueue_job' do
        expect(model).to receive(:enqueue_job)
        get :run_job, xhr: true, params: { id: model.id }, format: :js
      end
    end

    context 'When status is "queued"' do
      it 'calls model#enqueue_job' do
        expect(model).to receive(:enqueue_job)
        get :run_job, xhr: true, params: { id: model.id }, format: :js
      end
    end
  end

  describe '#cancel_job' do
    let(:model) { FactoryGirl.create model_class.name.underscore }
    before do
      allow(model_class).to receive(:find).and_return(model)
    end

    it 'calls model#cancel_scheduled_runs' do
      expect(model).to receive(:cancel_scheduled_runs)
      delete :cancel_job, params: { id: model.id }, format: :js
    end

    it 'renders jobs/cancel' do
      expect(model).to receive(:cancel_scheduled_runs)
      delete :cancel_job, xhr: true, params: { id: model.id }, format: :js
      expect(response).to render_template('jobs/cancel_job')
    end
  end

  describe '#destroy' do
    let(:model) { FactoryGirl.create model_class.name.underscore }
    before do
      allow(model_class).to receive(:destroy).and_return(model)
    end

    it 'renders jobs/destroy' do
      delete :destroy, params: { id: model.id }, format: :js
      expect(response).to render_template('jobs/destroy')
    end
  end

  describe '#archive' do
    let(:model) { FactoryGirl.create model_class.name.underscore }
    before do
      allow(model_class).to receive(:find).and_return(model)
    end

    it 'sets model#archive to true' do
      get :archive, xhr: true, params: { id: model.id }, format: :js
      expect(model.reload.archive).to be_truthy
    end

    it 'renders jobs/archive' do
      get :archive, xhr: true, params: { id: model.id }, format: :js
      expect(response).to render_template('jobs/archive')
    end
  end
end
