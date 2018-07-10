RSpec.describe Archivematica::StartTransferJob do
  ENV['AM_URL'] = 'http://test.host'
  ENV['AM_USER'] = 'test'
  ENV['AM_KEY'] = '1234'
  ENV['AM_TS'] = 'location'

  describe 'successful job' do
    before do
      stub_request(:post, 'http://test.host/api/transfer/start_transfer/')
        .to_return(status: 200, body: { message: 'Copy successful.', path: 'path' }.to_json)
      allow(Archivematica::ApproveTransferJob).to receive(:perform_later)
      allow(Archivematica::ApproveTransferJob).to receive(:set).and_return(Archivematica::ApproveTransferJob)
      allow(JobStatusService).to receive(:new)
    end
    it 'performs the job, queues the next job and calls the job status service' do
      expect(Archivematica::ApproveTransferJob).to receive(:set).with(wait: 30.seconds)
      expect(Archivematica::ApproveTransferJob).to receive(:perform_later)
      expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'success', message: '200: Copy successful.'))
      described_class.perform_now(
        job_status_id: 'job_status_id',
        name: 'name',
        path: 'path'
      )
    end
  end

  describe 'unsuccessful job, do not retry' do
    before do
      stub_request(:post, 'http://test.host/api/transfer/start_transfer/')
        .to_return(status: 418, body: {}.to_json, headers: { warning: 'warning message' })
      allow(Archivematica::ApproveTransferJob).to receive(:perform_later)
      allow(Archivematica::ApproveTransferJob).to receive(:set).and_return(Archivematica::ApproveTransferJob)
      allow(JobStatusService).to receive(:new)
    end
    it 'performs the job, queues the next job and calls the job status service' do
      expect(Archivematica::ApproveTransferJob).not_to receive(:perform_later)
      expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'error', message: '418: name and path are required'))
      described_class.perform_now(
        job_status_id: 'job_status_id',
        name: nil,
        path: 'path'
      )
    end

    describe 'unsuccessful job, retry' do
      before do
        stub_request(:post, 'http://test.host/api/transfer/start_transfer/')
          .to_return(status: 500, body: { message: 'error details in body message' }.to_json, headers: { warning: 'warning message' })
        allow(Archivematica::ApproveTransferJob).to receive(:perform_later)
        allow(JobStatusService).to receive(:new)
      end
      it 'performs the job, queues the next job and calls the job status service' do
        expect(Archivematica::ApproveTransferJob).not_to receive(:perform_later)
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'retry', message: '500: error details in body message'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          name: 'name',
          path: 'path'
        )
      end
    end
  end
end
