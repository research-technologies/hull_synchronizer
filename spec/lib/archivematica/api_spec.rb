RSpec.describe Archivematica::Api do
  let(:factory) { double(Archivematica::ApiFactory) }

  ENV['AM_URL'] = 'http://test.host'
  ENV['AM_USER'] = 'test'
  ENV['AM_KEY'] = '1234'
  ENV['AM_TS'] = 'transfer_source_location'

  describe '#start_transfer' do
    let(:start_transfer) do
      described_class::StartTransfer.new(
        params: { name: 'name', path: ['path'], type: 'standard', accession: 'accession' }
      )
    end

    before do
      stub_request(:post, 'http://test.host/api/transfer/start_transfer/')
        .to_return(status: 200)
    end

    context 'with valid params' do
      it 'returns the params' do
        expect(start_transfer.params).to eq(name: 'name', path: ['path'], type: 'standard', accession: 'accession')
      end
      it 'makes the right api call' do
        expect(start_transfer.request.status).to eq(200)
      end
    end

    context 'with invalid params' do
      let(:start_transfer) { described_class::StartTransfer.new(params: {}) }

      it 'responds with a Faraday::Response containing a warning header' do
        expect(start_transfer.request.headers[:warning]).to eq('name and path are required')
      end
    end

    context 'with read timeout' do
      before do
        stub_request(:post, 'http://test.host/api/transfer/start_transfer/').to_timeout
      end
      it 'returns a 598' do
        expect(start_transfer.request.status).to eq(598)
        expect(start_transfer.request.headers[:warning]).to eq('execution expired')
      end
    end
  end

  describe '#approve_transfer' do
    let(:approve_transfer) { described_class::ApproveTransfer.new(params: { directory: 'directory', type: 'standard' }) }

    before do
      stub_request(:post, 'http://test.host/api/transfer/approve')
        .to_return(status: 200)
    end

    context 'with valid params' do
      it 'returns the params' do
        expect(approve_transfer.params).to eq(directory: 'directory', type: 'standard')
      end
      it 'makes the right api call' do
        expect(approve_transfer.request.status).to eq(200)
      end
    end

    context 'with invalid params' do
      let(:approve_transfer) { described_class::ApproveTransfer.new(params: {}) }

      it 'responds with a Faraday::Response containing a warning header' do
        expect(approve_transfer.request.headers[:warning]).to eq('directory is required')
      end
    end
  end

  describe '#unapproved_transfers' do
    let(:unapproved_transfers) { described_class::UnapprovedTransfers.new(params: {}) }

    before do
      stub_request(:get, 'http://test.host/api/transfer/unapproved')
        .to_return(status: 200)
    end

    context 'with valid params' do
      it 'makes the right api call' do
        expect(unapproved_transfers.request.status).to eq(200)
      end
    end

    context 'with a Faraday::Error' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/unapproved').to_raise(Faraday::ClientError)
      end

      it 'responds with a faraday response and http 418 code' do
        expect(unapproved_transfers.request.status).to eq(418)
      end
    end
  end

  describe '#transfer_status' do
    let(:transfer_status) { described_class::TransferStatus.new(params: { uuid: '12345' }) }

    before do
      stub_request(:get, 'http://test.host/api/transfer/status/12345/')
        .to_return(status: 200)
    end

    context 'with valid params' do
      it 'returns the params' do
        expect(transfer_status.params).to eq(uuid: '12345')
      end
      it 'makes the right api call' do
        expect(transfer_status.request.status).to eq(200)
      end
    end

    context 'with invalid params' do
      let(:transfer_status) { described_class::TransferStatus.new(params: {}) }

      it 'responds with a Faraday::Response containing a warning header' do
        expect(transfer_status.request.headers[:warning]).to eq('uuid is required')
      end
    end
  end

  describe '#ingest_status' do
    let(:ingest_status) { described_class::IngestStatus.new(params: { uuid: '12345' }) }

    before do
      stub_request(:get, 'http://test.host/api/ingest/status/12345/')
        .to_return(status: 200)
    end

    context 'with valid params' do
      it 'returns the params' do
        expect(ingest_status.params).to eq(uuid: '12345')
      end
      it 'makes the right api call' do
        expect(ingest_status.request.status).to eq(200)
      end
    end

    context 'with invalid params' do
      let(:ingest_status) { described_class::IngestStatus.new(params: {}) }

      it 'responds with a Faraday::Response containing a warning header' do
        expect(ingest_status.request.headers[:warning]).to eq('uuid is required')
      end
    end
  end

  describe '#package_details' do
    let(:package_details) { described_class::PackageDetails.new(params: { uuid: '12345' }) }

    before do
      ENV['SS_URL'] = 'http://test_ss.host'
      ENV['SS_USER'] = 'test'
      ENV['SS_KEY'] = '1234'
      stub_request(:get, 'http://test_ss.host/api/v2/file/12345/')
        .to_return(status: 200)
    end

    context 'with valid params' do
      it 'returns the params' do
        expect(package_details.params).to eq(uuid: '12345')
      end
      it 'makes the right api call' do
        expect(package_details.request.status).to eq(200)
      end
    end

    context 'with invalid params' do
      let(:package_details) { described_class::PackageDetails.new(params: {}) }

      it 'responds with a Faraday::Response containing a warning header' do
        expect(package_details.request.headers[:warning]).to eq('uuid is required')
      end
    end

    context '#dip_uuids' do
      it 'extracts the dip_uuids' do
        expect(package_details.dip_uuids(['path/to/uuid/'])).to eq(['uuid'])
      end
    end

    describe '#connection' do
      let(:start_transfer) do
        described_class::StartTransfer.new(
          params: { name: 'name', path: ['path'] }
        )
      end

      before do
        ENV['AM_URL'] = ''
      end
      it 'responds with a Faraday::Response containing a warning header' do
        expect(start_transfer.request.headers[:warning]).to eq('environment variables are not set')
      end
      after do
        ENV['AM_URL'] = 'http://test.host'
      end
    end
  end
end
