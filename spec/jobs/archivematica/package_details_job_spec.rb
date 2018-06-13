RSpec.describe Archivematica::PackageDetailsJob do
  ENV['SS_URL'] = 'http://test.host'
  ENV['SS_USER'] = 'test'
  ENV['SS_KEY'] = '1234'

  describe 'successful request' do
    before do
      allow(JobStatusService).to receive(:new)
      allow(Archivematica::PackageDetailsJob).to receive(:perform_later)
    end

    context 'UPLOADED (both)' do
      before do
        stub_request(:get, 'http://test.host/api/v2/file/uuid/')
          .to_return(status: 200, body: { status: 'UPLOADED', uuid: 'uuid', related_packages: ['/api/v2/file/dip_uuid/'] }.to_json)
        stub_request(:get, 'http://test.host/api/v2/file/dip_uuid/')
          .to_return(status: 200, body: { status: 'UPLOADED', uuid: 'dip_uuid' }.to_json)
      end
      it 'performs the job, calls the dip_response' do
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'success', message: '200: UPLOADED'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end

    context 'UPLOADED (aip only)' do
      before do
        stub_request(:get, 'http://test.host/api/v2/file/uuid/')
          .to_return(status: 200, body: { status: 'UPLOADED', uuid: 'uuid', related_packages: ['/api/v2/file/dip_uuid/'] }.to_json)

        stub_request(:get, 'http://test.host/api/v2/file/dip_uuid/')
          .to_return(status: 200, body: { status: 'SOMETHING_ELSE', uuid: 'dip_uuid' }.to_json)
      end
      it 'performs the job, calls the dip_response' do
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'retry', message: '200: SOMETHING_ELSE'))
        expect(Archivematica::PackageDetailsJob).to receive(:perform_later).with(job_status_id: 'job_status_id', uuid: 'uuid')
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end

    context 'UPLOADED (neither)' do
      before do
        stub_request(:get, 'http://test.host/api/v2/file/uuid/')
          .to_return(status: 200, body: { status: 'SOMETHING_ELSE', uuid: 'uuid', related_packages: ['/api/v2/file/dip_uuid/'] }.to_json)

        stub_request(:get, 'http://test.host/api/v2/file/dip_uuid/')
          .to_return(status: 200, body: { status: 'SOMETHING_ELSE', uuid: 'dip_uuid' }.to_json)
      end
      it 'performs the job, calls the dip_response' do
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'retry', message: '200: SOMETHING_ELSE'))
        expect(Archivematica::PackageDetailsJob).to receive(:perform_later).with(job_status_id: 'job_status_id', uuid: 'uuid')
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end
  end
end
