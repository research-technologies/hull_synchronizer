RSpec.describe Archivematica::ApproveTransferJob do
  ENV['AM_URL'] = 'http://test.host'
  ENV['AM_USER'] = 'test'
  ENV['AM_KEY'] = '1234'
  ENV['AM_TS'] = 'location'

  describe 'successful job' do
    before do
      stub_request(:post, 'http://test.host/api/transfer/approve')
        .to_return(status: 200, body: { message: 'Approval successful.', uuid: 'uuid' }.to_json)
      allow(Archivematica::TransferStatusJob).to receive(:set).and_return(Archivematica::TransferStatusJob)
      allow(Archivematica::TransferStatusJob).to receive(:perform_later)
      allow(JobStatusService).to receive(:new)
    end
    it 'performs the job, queues the next job and calls the job status service' do
      expect(Archivematica::TransferStatusJob).to receive(:set).with(wait: 5.minutes)
      expect(Archivematica::TransferStatusJob).to receive(:perform_later)
      expect(JobStatusService).to receive(:new).with(hash_including(:job, job_status_id: 'job_status_id', status: 'success', message: '200: Approval successful.'))
      described_class.perform_now(
        job_status_id: 'job_status_id',
        directory: 'directory'
      )
    end
  end

  describe 'unsuccessful job, do not retry' do
    before do
      stub_request(:post, 'http://test.host/api/transfer/approve')
        .to_return(status: 418, body: {}.to_json, headers: { warning: 'warning message' })
      allow(Archivematica::TransferStatusJob).to receive(:perform_later)
      allow(JobStatusService).to receive(:new)
    end
    it 'performs the job, queues the next job and calls the job status service' do
      expect(Archivematica::TransferStatusJob).not_to receive(:perform_later)
      expect(JobStatusService).to receive(:new).with(hash_including(:job, job_status_id: 'job_status_id', status: 'error', message: '418: directory is required'))
      described_class.perform_now(
        job_status_id: 'job_status_id',
        directory: nil
      )
    end

    describe 'unsuccessful job, retry' do
      before do
        stub_request(:post, 'http://test.host/api/transfer/approve')
          .to_return(status: 500, body: { message: 'error details in message body' }.to_json, headers: { warning: 'warning message' })
        allow(Archivematica::TransferStatusJob).to receive(:perform_later)
        allow(JobStatusService).to receive(:new)
      end
      it 'performs the job, queues the next job and calls the job status service' do
        expect(Archivematica::TransferStatusJob).not_to receive(:perform_later)
        expect(JobStatusService).to receive(:new).with(hash_including(:job, job_status_id: 'job_status_id', status: 'retry', message: '500: error details in message body'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          directory: 'directory'
        )
      end
    end
  end
end
