require 'dip_reader'

RSpec.describe DIPReader do
  let(:reader) { described_class.new(dip_location) }

  describe 'dip_reader' do
    context 'with invalid dip_location' do
      let(:dip_location) { 'some_incorrect_path' }
      it 'raises an error' do
        expect { reader }.to raise_error(RuntimeError, 'Cannot find DIP folder: some_incorrect_path')
      end
    end

    context 'with valid dip_location' do
      let(:dip_location) { 'spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7' }
      it 'sets the correct attributes' do
        expect(reader.dip_folder).to eq(dip_location)
        expect(reader.content_struct).to be_a(Nokogiri::XML::Element)
        expect(reader.package).to eq(['spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7/processingMCP.xml', 'spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7/METS.bff59767-3d3f-4032-914c-c7ebebf87aa7.xml', 'spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7/objects/eb0739b6-f103-40e8-8564-1b4fd0261383-DESCRIPTION.csv', 'spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7/objects/da911114-8ad8-4b0f-97c1-2ffe67c392cd-FILES.csv', 'spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7/objects/a0f43446-5488-4f54-840e-574692594504-something.docx'])
        expect(reader.works).to eq("work1" => ["spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7/objects/545a34f5-8e0e-42d6-8530-8202c3924065-metadata.json", "spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7/objects/ca77863e-dd5b-43bb-9f9d-abcbf40c1c02-snow-cap.jpg"])
      end
    end
  end
end
