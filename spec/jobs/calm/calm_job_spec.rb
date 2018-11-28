RSpec.describe Calm::CalmJob do
  let(:subject) { described_class.new }
  let(:calm_api) { instance_double(Calm::Api) }
  let(:metadata_incoming) { { calm_metadata: { reference: 'Collection', filename: 'my file', accession_number: 'abc' } } }

  describe 'successful job' do
    before do
      allow(subject).to receive(:setup_calm)
      allow(calm_api).to receive(:get_record_by_field).with('RefNo', 'Collection').and_return([true, { 'RecordID' => ['12345'] }])
      allow(calm_api).to receive(:create_child_record).and_return([true, '12345'])

      subject.calm_api = calm_api
      subject.params = 0
      subject.payloads = [
        { output: {
          work_id: 'hyrax_work',
          works: [metadata_incoming]
        } }
      ]
    end
    context 'with only mandatory metdata' do
      it 'performs the job and sets the payload for the next job' do
        expect(subject).to receive(:output).with(event: 'success', message: '12345 successfully added to CALM', works: [metadata_incoming])
        subject.perform
      end
      it 'contains default values for language and access_status, and the hyrax_work id' do
        subject.perform
        expect(subject.fields).to eq("Title" => "File name: my file", "AccNo" => "abc", "AccessStatus" => "closed", "Language" => "English", "Location" => "hyrax_work")
      end
    end

    context 'with additional metadata' do
      let(:metadata_incoming) { { calm_metadata: { reference: 'Collection', filename: 'my file', accession_number: 'abc', title: 'Title', language: 'German', access_status: 'open', description: 'description', user_description: 'user description' } } }

      it 'contains the supplied values, not the defaults' do
        subject.perform
        expect(subject.fields).to eq("Title" => "Title", "AccNo" => "abc", "AccessStatus" => "open", "Description" => "description\nUser Description: description", "Language" => "German", "Location" => "hyrax_work")
      end
    end
  end

  describe 'unsuccessful job, do not retry' do
    before do
      allow(subject).to receive(:setup_calm)
      allow(calm_api).to receive(:get_record_by_field).with('RefNo', 'Collection').and_return([false, 'An error!'])
      allow(calm_api).to receive(:create_child_record).and_return([false, 'Another error!'])

      subject.calm_api = calm_api
      subject.params = 0
      subject.payloads = [
        { output: {
          work_id: 'hyrax_work',
          works: [metadata_incoming]
        } }
      ]
    end
    it 'performs the job and sets the payload for the next job' do
      expect(subject).to receive(:output).with(event: 'failed', message: 'Job failed with: Another error!')
      subject.perform
    end
  end
end
