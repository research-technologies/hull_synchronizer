class ReceivePackageWorkflow < Gush::Workflow
  attr_reader :number_of_works

  # @params params [Hash] supply any params needed to start the first job
  def configure(params)
    run ReceivePackageJob, params: params
    run CheckSubmissionJob, after: ReceivePackageJob
    run InformUserJob, after: CheckSubmissionJob
  end

end
