RSpec.describe Archivematica::PackageDetailsJob do
  ENV['SS_URL'] = 'http://test.host'
  ENV['SS_USER'] = 'test'
  ENV['SS_KEY'] = '1234'

  let(:subject) { described_class.new }

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
      subject.payloads = [{ output: { uuid: 'uuid', accession: 'accession' } }]
    end

    context 'UPLOADED (both)' do
      before do
        stub_request(:get, 'http://test.host/api/v2/file/uuid/')
          .to_return(status: 200, body: aip_body.to_json)
        stub_request(:get, 'http://test.host/api/v2/file/dip_uuid/')
          .to_return(status: 200, body: dip_body.to_json)
      end
      it 'produces the metadata hash' do
        expect(subject).to receive(:output).with(
          event: 'success',
          message: '',
          dip_location: '/var/archivematica/sharedDirectory/www/DIPsStore/dip_uuid.7z',
          package_metadata: { aip_current_full_path: '/var/archivematica/sharedDirectory/www/AIPsStore/aip_uuid.7z',
                              aip_current_location: '/api/v2/location/aip_uuid/',
                              aip_current_path: 'uuid.7z',
                              origin_pipeline: '/api/v2/pipeline/aa68b424-28d5-455c-b27b-f3081a2114a6/',
                              aip_resource_uri: '/api/v2/file/aip_uuid/',
                              aip_size: 3_335_521,
                              aip_status: 'UPLOADED',
                              aip_uuid: 'aip_uuid',
                              accession: 'accession',
                              dip_current_full_path: '/var/archivematica/sharedDirectory/www/DIPsStore/dip_uuid.7z',
                              dip_current_location: '/api/v2/location/dip_uuid/',
                              dip_current_path: 'dip_uuid.7z',
                              dip_resource_uri: '/api/v2/file/dip_uuid/',
                              dip_size: 3_335_521,
                              dip_status: 'UPLOADED',
                              dip_uuid: 'dip_uuid' }
        )
        subject.perform
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
        expect(subject).to receive(:output).with(event: 'retry', message: '')
        subject.perform
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
        expect(subject).to receive(:output).with(event: 'retry', message: '')
        subject.perform
      end
    end
  end
end
