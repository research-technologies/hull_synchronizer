RSpec.describe Sword::DepositJob do
  ENV['SWORD_ENDPOINT'] = 'http://test.host'
  let(:subject) { described_class.new }
  let(:sword_api) { instance_double(Sword::Api::Work) }
  let(:reponse_body) { File.read('spec/fixtures/files/work.xml') }
  let(:calm_job) {instance_double(Calm::CreateComponentJob)}

  describe 'successful job' do
    before do
      stub_request(:post, 'http://test.host/sword/collections/default/works')
        .to_return(status: 201, body: reponse_body)
      subject.params = 0
      subject.payloads = [
        { output: { works: [
          {
            file: { path: "spec/fixtures/files/sword/hh63sv88v.zip",
                    content_type: 'application/zip' },
            packaging: 'http://purl.org/net/sword/package/BagIt'
          }
        ] } }
      ]
    end
    it 'performs the job successfully, retains payload for next job' do
      allow(Calm::CreateComponentJob).to receive(:new).and_return(calm_job)
      allow(calm_job).to receive(:perform).and_return({ event: 'success', message: '' })
      expect(subject).to receive(:output).with(event: 'success', message: 'hh63sv88v successfully deposited; ', package_id: nil, works: subject.payloads.first[:output][:works])
      subject.perform
    end
  end

  describe 'unsuccessful job' do
    before do
      stub_request(:post, 'http://test.host/sword/collections/default/works')
        .to_return(status: 500, body: '')
      subject.params = 0
      subject.payloads = [
        { output: { works: [
          {
            file: { path: "spec/fixtures/files/sword/hh63sv88v.zip",
                    content_type: 'application/zip' },
            packaging: 'http://purl.org/net/sword/package/BagIt'
          }
        ] } }
      ]
    end
    it 'performs the job successfully, retains payload for next job' do
      expect(subject).to receive(:output).with(event: 'failed', message: '')
      subject.perform
    end
  end
end
