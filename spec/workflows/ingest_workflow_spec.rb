RSpec.describe IngestWorkflow do
  let(:ingest_workflow) { described_class.create({}) }
  let(:job_names) { ingest_workflow.jobs.collect(&:outgoing) }
  let(:initial_jobs) { ingest_workflow.initial_jobs }

  describe 'Workflow' do
    it 'sets up five jobs' do
      expect(ingest_workflow.jobs.length).to eq 5
    end
    it 'sets up start transfer as the first job' do
      expect(initial_jobs.length).to eq 1
      expect(initial_jobs.first.name).to include('StartTransferJob')
    end
    it 'sets up the five jobs in the right order' do
      expect(job_names[0].first).to include('ApproveTransferJob')
      expect(job_names[1].first).to include('TransferStatusJob')
      expect(job_names[2].first).to include('IngestStatusJob')
      expect(job_names[3].first).to include('PackageDetailsJob')
    end
  end
end
