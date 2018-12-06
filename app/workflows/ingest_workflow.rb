class IngestWorkflow < Gush::Workflow
  attr_reader :number_of_works

  # @params params [Hash] supply any params needed to start the first job
  #   params[number_of_works:] is required and must be an integer to indicate
  #   the number of individual works to be deposited (not including the package)
  def configure(params)
    if params[:number_of_works] # && params[:number_of_works].is_a?(Integer)
      @number_of_works = params[:number_of_works]
    else
      @number_of_works = 0
    end
    run ProcessSubmissionJob, params: params
    run Archivematica::StartTransferJob, after: ProcessSubmissionJob
    run Archivematica::ApproveTransferJob, after: Archivematica::StartTransferJob
    run Archivematica::TransferStatusJob, after: Archivematica::ApproveTransferJob
    run Archivematica::IngestStatusJob, after: Archivematica::TransferStatusJob
    run Archivematica::PackageDetailsJob, after: Archivematica::IngestStatusJob
    run ProcessDIPJob, after: Archivematica::PackageDetailsJob
    run Sword::DepositPackageJob, after: ProcessDIPJob

    number_of_works.times.each do |index|
      run Sword::DepositJob, after: Sword::DepositPackageJob, params: index
      run Calm::CalmJob, after: Sword::DepositJob, params: index
    end
  end

end
