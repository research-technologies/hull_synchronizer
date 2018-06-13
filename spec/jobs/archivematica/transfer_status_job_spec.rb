RSpec.describe Archivematica::TransferStatusJob do
  ENV['AM_URL'] = 'http://test.host'
  ENV['AM_USER'] = 'test'
  ENV['AM_KEY'] = '1234'
  ENV['AM_TS'] = 'location'

  describe 'successful job' do
    before do
      allow(Archivematica::IngestStatusJob).to receive(:set).and_return(Archivematica::IngestStatusJob)
      allow(Archivematica::TransferStatusJob).to receive(:set).and_return(Archivematica::TransferStatusJob)
      allow(Archivematica::IngestStatusJob).to receive(:perform_later)
      allow(Archivematica::TransferStatusJob).to receive(:perform_later)
      allow(JobStatusService).to receive(:new)
    end

    context 'COMPLETE' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'COMPLETE', uuid: 'uuid' }.to_json)
      end
      it 'performs the job, queues the next job and calls the job status service' do
        expect(Archivematica::IngestStatusJob).to receive(:set).with(wait: 5.minutes)
        expect(Archivematica::IngestStatusJob).to receive(:perform_later)
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'success', message: '200: COMPLETE'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end
    context 'PROCESSING' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'PROCESSING', uuid: 'uuid' }.to_json)
      end
      it 'performs the job, queues the next job and calls the job status service' do
        expect(Archivematica::TransferStatusJob).to receive(:set).with(wait: 5.minutes)
        expect(Archivematica::TransferStatusJob).to receive(:perform_later)
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'retry', message: '200: PROCESSING'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end

    context 'USER_INPUT' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'USER_INPUT', uuid: 'uuid' }.to_json)
      end
      it 'performs the job, queues the next job and calls the job status service' do
        expect(Archivematica::TransferStatusJob).to receive(:set).with(wait: 1.days)
        expect(Archivematica::TransferStatusJob).to receive(:perform_later)
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'retry', message: '200: USER_INPUT'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end

    context 'ERROR' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'ERROR', uuid: 'uuid' }.to_json)
      end
      it 'performs the job, queues the next job and calls the job status service' do
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'error', message: '200: ERROR'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end
  end

  describe 'unsuccessful job, do not retry' do
    before do
      stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
        .to_return(status: 418, body: {}.to_json, headers: { warning: 'warning message' })
      allow(Archivematica::IngestStatusJob).to receive(:perform_later)
      allow(JobStatusService).to receive(:new)
    end
    it 'performs the job, queues the next job and calls the job status service' do
      expect(Archivematica::IngestStatusJob).not_to receive(:perform_later)
      expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'error', message: '418: uuid is required'))
      described_class.perform_now(
        job_status_id: 'job_status_id',
        uuid: nil
      )
    end

    describe 'unsuccessful job, retry' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 500, body: { message: 'error details in message body' }.to_json, headers: { warning: 'warning message' })
        allow(Archivematica::IngestStatusJob).to receive(:perform_later)
        allow(JobStatusService).to receive(:new)
      end
      it 'performs the job, queues the next job and calls the job status service' do
        expect(Archivematica::IngestStatusJob).not_to receive(:perform_later)
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'retry', message: '500: error details in message body'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end
  end
end
