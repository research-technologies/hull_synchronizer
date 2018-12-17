RSpec.describe ProcessDIPJob do
  let(:subject) { described_class.new }
  let(:processor) { DIPProcessor }
  let(:processor_instance) { instance_double(DIPProcessor) }
  let(:output_body) do
    { event: "success", message: "DIPs processed", package: { file: { path: "tmp/5abec3c8-1f0c-4517-9ebd-745d5a1e90fc.zip", content_type: "application/zip" }, hyrax_work_model: "Package", packaging: "http://purl.org/net/sword/package/BagIt" }, works: { works: [{ file: { path: "tmp/5abec3c8-1f0c-4517-9ebd-745d5a1e90fc_work1.zip", content_type: "application/zip" }, packaging: "http://purl.org/net/sword/package/BagIt", calm_metadata: { filename: "Test.JPG", accession_number: "2018-123", reference: "U TEST", packaged_by_package_name: "5abec3c8-1f0c-4517-9ebd-745d5a1e90fc" } }] } }
  end

  describe 'successful job' do
    before do
      subject.payloads = [
        { output: {
          dip_location: 'path_to_dip',
          package_metadata: { dip_uuid: 'dip_uuid' }
        } }
      ]
      allow(processor).to receive(:new).with(params: subject.payloads.first[:output]).and_return(processor_instance)
      allow(processor_instance).to receive(:process)
      allow(processor_instance).to receive(:cleanup)
      allow(processor_instance).to receive(:package_payload).and_return(file: { path: "tmp/5abec3c8-1f0c-4517-9ebd-745d5a1e90fc.zip", content_type: "application/zip" }, hyrax_work_model: "Package", packaging: "http://purl.org/net/sword/package/BagIt")
      allow(processor_instance).to receive(:works_payload).and_return(works: [{ file: { path: "tmp/5abec3c8-1f0c-4517-9ebd-745d5a1e90fc_work1.zip", content_type: "application/zip" }, packaging: "http://purl.org/net/sword/package/BagIt", calm_metadata: { filename: "Test.JPG", accession_number: "2018-123", reference: "U TEST", packaged_by_package_name: "5abec3c8-1f0c-4517-9ebd-745d5a1e90fc" } }])
    end
    it 'sets the output for the next job' do
      expect(subject).to receive(:output).with(output_body)
      subject.perform
    end
  end
  
  describe 'unsuccessful job' do
    before do
      subject.payloads = [
        { output: {
          dip_location: 'path_to_dip',
          package_metadata: { dip_uuid: 'dip_uuid' }
        } }
      ]
      allow(processor).to receive(:new).with(params: subject.payloads.first[:output]).and_return(processor_instance)
      allow(processor_instance).to receive(:process).and_raise("boom")
      allow(processor_instance).to receive(:cleanup)
    end
    it 'sets the output for the next job' do
      expect(subject).to receive(:output).with(event: 'failed', message: 'boom', package: nil, works: nil)
      subject.perform
    end
  end
end
