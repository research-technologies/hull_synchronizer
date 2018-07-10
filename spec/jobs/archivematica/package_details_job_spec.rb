RSpec.describe Archivematica::PackageDetailsJob do
  ENV['SS_URL'] = 'http://test.host'
  ENV['SS_USER'] = 'test'
  ENV['SS_KEY'] = '1234'

  let(:dip_body) do
    { current_full_path: '/var/archivematica/sharedDirectory/www/DIPsStore/dip_uuid.7z',
      current_location: '/api/v2/location/dip_uuid/',
      current_path: 'dip_uuid.7z',
      misc_attributes: {},
      origin_pipeline: '/api/v2/pipeline/aa68b424-28d5-455c-b27b-f3081a2114a6/',
      package_type: 'DIP',
      related_packages: [
        '/api/v2/file/dip_uuid/'
      ],
      resource_uri: '/api/v2/file/dip_uuid/',
      size: 3_335_521,
      status: 'UPLOADED',
      uuid: 'dip_uuid' }
  end

  let(:aip_body) do
    { current_full_path: '/var/archivematica/sharedDirectory/www/AIPsStore/aip_uuid.7z',
      current_location: '/api/v2/location/aip_uuid/',
      current_path: 'uuid.7z',
      misc_attributes: {},
      origin_pipeline: '/api/v2/pipeline/aa68b424-28d5-455c-b27b-f3081a2114a6/',
      package_type: 'AIP',
      related_packages: [
        '/api/v2/file/dip_uuid/'
      ],
      resource_uri: '/api/v2/file/aip_uuid/',
      size: 3_335_521,
      status: 'UPLOADED',
      uuid: 'aip_uuid' }
  end

  describe 'successful request' do
    before do
      allow(JobStatusService).to receive(:new)
      allow(described_class).to receive(:perform_later)
      allow(UnpackDipForDepositJob).to receive(:perform_later)
    end

    context 'UPLOADED (both)' do
      before do
        stub_request(:get, 'http://test.host/api/v2/file/uuid/')
          .to_return(status: 200, body: aip_body.to_json)
        stub_request(:get, 'http://test.host/api/v2/file/dip_uuid/')
          .to_return(status: 200, body: dip_body.to_json)
      end
      it 'performs the job, calls the dip_response' do
        expect(JobStatusService).to receive(:new).with(hash_including(:job_status_id, :job, status: 'success', message: '200: UPLOADED'))
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
      it 'produces the metadata hash' do
        expect(UnpackDipForDepositJob).to receive(:perform_later).with(hash_including(
                                                                         :metadata,
                                                                         job_status_id: 'job_status_id',
                                                                         dip_location: '/var/archivematica/sharedDirectory/www/DIPsStore/dip_uuid.7z'
        ))
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
        expect(described_class).to receive(:perform_later).with(job_status_id: 'job_status_id', uuid: 'uuid')
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
        expect(described_class).to receive(:perform_later).with(job_status_id: 'job_status_id', uuid: 'uuid')
        described_class.perform_now(
          job_status_id: 'job_status_id',
          uuid: 'uuid'
        )
      end
    end
  end
end
