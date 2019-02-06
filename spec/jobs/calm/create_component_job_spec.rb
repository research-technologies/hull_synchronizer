RSpec.describe Calm::CreateComponentJob do
  let(:calm_job) { described_class.new }
  let(:calm_api) { instance_double(Calm::Api) }
  let(:calm_metadata) do
    {
      reference: 'Collection',
      filename: 'my file',
      accession_number: 'abc'
    }
  end
  let(:metadata_incoming) do
    {
      work_id: 'hyrax_work',
      calm_metadata: calm_metadata
    }
  end

  describe 'successful job' do
    before do
      allow(calm_job).to receive(:setup_calm)
      allow(calm_api).to receive(:get_record_by_field).with('RefNo', 'Collection').and_return([true, { 'RecordID' => ['12345'] }])
      allow(calm_api).to receive(:create_child_record).and_return([true, '12345'])

      calm_job.calm_api = calm_api
      calm_job.params = metadata_incoming
      calm_job.payloads = [
        { output: {
          works: [calm_metadata]
        } }
      ]
    end
    context 'with only mandatory metdata' do
      it 'performs the job and sets the payload for the next job' do
        expect(calm_job.perform).to eq(event: 'success', message: '12345 successfully added to CALM')
      end
      it 'contains default values for language and access_status, and the hyrax_work id' do
        calm_job.perform
        expect(calm_job.fields).to eq("Title" => "File name: my file", "AccNo" => "abc", "AccessStatus" => "closed", "Language" => "English", "URL" => "hyrax_work")
      end
    end

    context 'with additional metadata' do
      let(:calm_metadata) { { reference: 'Collection', filename: 'my file', accession_number: 'abc', title: 'Title', language: 'German', access_status: 'open', description: 'description', user_description: 'user description' } }

      it 'contains the supplied values, not the defaults' do
        calm_job.perform
        expect(calm_job.fields).to eq("Title" => "Title", "AccNo" => "abc", "AccessStatus" => "open", "Description" => "description\nUser Description: description", "Language" => "German", "URL" => "hyrax_work")
      end
    end
  end

  describe 'unsuccessful job, do not retry' do
    before do
      allow(calm_job).to receive(:setup_calm)
      allow(calm_api).to receive(:get_record_by_field).with('RefNo', 'Collection').and_return([false, 'An error!'])
      allow(calm_api).to receive(:create_child_record).and_return([false, 'Another error!'])

      calm_job.calm_api = calm_api
      calm_job.params = metadata_incoming
      calm_job.payloads = [
        { output: {
          works: [calm_metadata]
        } }
      ]
    end
    it 'performs the job and sets the payload for the next job' do
      expect(calm_job.perform).to eq(event: 'failed', message: 'Job failed with: Another error!')
    end
  end
end
