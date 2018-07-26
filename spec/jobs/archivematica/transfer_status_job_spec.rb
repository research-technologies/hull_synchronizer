RSpec.describe Archivematica::TransferStatusJob do
  ENV['AM_URL'] = 'http://test.host'
  ENV['AM_USER'] = 'test'
  ENV['AM_KEY'] = '1234'
  ENV['AM_TS'] = 'location'

  let(:subject) { described_class.new }

  describe 'successful job' do
    before do
      subject.payloads = [{ output: { uuid: 'uuid' } }]
    end

    context 'COMPLETE' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'COMPLETE', sip_uuid: 'uuid' }.to_json)
      end
      it 'performs the job and sets the payload for the next job' do
        expect(subject).to receive(:output).with(event: 'success', message: '', uuid: 'uuid')
        subject.perform
      end
    end
    context 'PROCESSING' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'PROCESSING', uuid: 'uuid' }.to_json)
      end
      it 'performs the job and sets the payload for the next job' do
        expect(subject).to receive(:output).with(event: 'retry', message: '')
        subject.perform
      end
    end

    context 'USER_INPUT' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'USER_INPUT', uuid: 'uuid' }.to_json)
      end
      it 'performs the job and sets the payload for the next job' do
        expect(subject).to receive(:output).with(event: 'retry', message: '')
        subject.perform
      end
    end

    context 'ERROR' do
      before do
        stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
          .to_return(status: 200, body: { status: 'ERROR', uuid: 'uuid' }.to_json)
      end
      it 'performs the job and sets the payload for the next job' do
        expect(subject).to receive(:output).with(event: 'failed', message: '')
        subject.perform
      end
    end
  end

  describe 'unsuccessful job, do not retry' do
    before do
      stub_request(:get, 'http://test.host/api/transfer/status/uuid/')
        .to_return(status: 418, body: {}.to_json, headers: { warning: 'warning message' })
      subject.payloads = [{ output: { uuid: 'uuid' } }]
    end
    it 'performs the job and sets the payload for the next job' do
      expect(subject).to receive(:output).with(event: 'failed', message: '')
      subject.perform
    end
  end
end
