shared_examples_for :scheduled_job do
  describe '#schedule' do
    context 'when #frequency=0' do
      before do
        allow(subject).to receive(:frequency).and_return(0)
      end

      it 'is nil' do
        expect(subject.schedule).to be_nil
      end
    end

    context 'when #frequency' do
      before do
        allow(subject).to receive(:frequency).and_return(5)
      end

      context 'when between configued backup times' do
        before do
          allow(ImportJob).to receive(:backup_start).and_return(Time.now - 60.minutes)
          allow(ImportJob).to receive(:backup_end).and_return(Time.now + 60.minutes)
        end

        it 'will be equal to configured backup end time' do
          expect(subject.schedule).to eql ImportJob.backup_end
        end
      end

      context '#last_run_at is nil' do
        before do
          allow(subject).to receive(:last_run_at).and_return(nil)
        end

        context '#run_at is nil' do
          before do
            allow(subject).to receive(:last_run_at).and_return(nil)
            # freze time
            now_time = Time.now
            allow(Time).to receive(:now).and_return(now_time)
          end

          it 'will return Time.now + frequency minutes' do
            expect(subject.schedule).to eql (Time.now + subject.frequency.minutes)
          end
        end

        context '#run_at has a time' do
          before do
            allow(subject).to receive(:run_at).and_return(Time.now)
          end

          it 'will return #run_at + frequency minutes' do
            expect(subject.schedule).to eql subject.run_at + subject.frequency.minutes
          end
        end
      end

      context '#last_run_at has a time' do
        before do
          allow(subject).to receive(:last_run_at).and_return(Time.now)
        end

        it 'will return #last_run_at + frequency minutes' do
          expect(subject.schedule).to eql subject.last_run_at + subject.frequency.minutes
        end
      end
    end
  end

  describe '#failure' do
    it 'sets status to failed' do
      subject.status = "runnning"
      expect{ subject.failure(nil) }.to change{ subject.status }.to('failed')
    end
  end

  describe '#next_scheduled_run' do
    context 'when job is scheduled in Delayed::Job' do
      before do
        subject.id = 1
        Delayed::Job.enqueue subject, run_at: 5.minutes.from_now
      end

      let(:scheduled_job) { Delayed::Job.last }

      it 'returns the #run_at time of the Delayed::Job instance' do
        expect(subject.next_scheduled_run).to eql scheduled_job.run_at
      end
    end
  end

  describe '#cancel_scheduled_runs' do
    context 'status is "scheduled"' do
      it 'changes status to ""' do
        subject.status = "scheduled"
        expect { subject.cancel_scheduled_runs }.to change{ subject.status }.to("")
      end
    end
  end
end
