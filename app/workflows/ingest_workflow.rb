class IngestWorkflow < Gush::Workflow
  def configure(params)
    # @todo: remove params from here and change StartTransferJob to use the payload once there is a preceding job
    run Archivematica::StartTransferJob, params: params
    run Archivematica::ApproveTransferJob, after: Archivematica::StartTransferJob
    run Archivematica::TransferStatusJob, after: Archivematica::ApproveTransferJob
    run Archivematica::IngestStatusJob, after: Archivematica::TransferStatusJob
    run Archivematica::PackageDetailsJob, after: Archivematica::IngestStatusJob
  end
end
