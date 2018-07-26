RSpec.describe Archivematica::ApproveTransferJob do
  ENV['AM_URL'] = 'http://test.host'
  ENV['AM_USER'] = 'test'
  ENV['AM_KEY'] = '1234'
  ENV['AM_TS'] = 'location'

  let(:subject) { described_class.new }

  describe 'successful job' do
    before do
      stub_request(:post, 'http://test.host/api/transfer/approve')
        .to_return(status: 200, body: { message: 'Approval successful.', uuid: 'uuid' }.to_json)
      subject.payloads = [{ output: { directory: 'directory' } }]
    end
    it 'performs the job and sets the payload for the next job' do
      expect(subject).to receive(:output).with(event: 'success', message: 'Approval successful.', uuid: 'uuid')
      subject.perform
    end
  end

  describe 'unsuccessful job, do not retry' do
    before do
      stub_request(:post, 'http://test.host/api/transfer/approve')
        .to_return(status: 418, body: { message: 'Something went wrong' }.to_json, headers: { warning: 'warning message' })
      subject.payloads = [{ output: { directory: 'directory' } }]
    end
    it 'performs the job and sets the payload for the next job' do
      expect(subject).to receive(:output).with(event: 'failed', message: 'Something went wrong')
      subject.perform
    end
  end
end
