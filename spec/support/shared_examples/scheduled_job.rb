shared_examples_for :scheduled_job do
  describe '#cancel_scheduled_runs' do
    context 'status is "scheduled"' do
      let!(:sidekiq_job) { double({ delete: nil }) }
      let!(:sidekiq_set) { double({ find: sidekiq_job }) }

      let!(:stubs) do 
        allow(Sidekiq::ScheduledSet).to receive(:new).and_return(sidekiq_set)
      end

      it 'changes status to ""' do
        subject.status = "scheduled"
        expect { subject.cancel_scheduled_runs }.to change{ subject.status }.to("")
      end

      it 'should call delete directly on the sidekiq job' do
        expect(sidekiq_job).to receive(:delete).with(any_args)
        subject.cancel_scheduled_runs
      end
    end
  end
end
