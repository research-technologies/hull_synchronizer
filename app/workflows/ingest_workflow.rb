class IngestWorkflow < Gush::Workflow
  def configure(params)
    # TODO: remove params here once previous job supplied them in payload
    run Archivematica::StartTransferJob, params: params
    run Archivematica::ApproveTransferJob, after: Archivematica::StartTransferJob
    run Archivematica::TransferStatusJob, after: Archivematica::ApproveTransferJob
    run Archivematica::IngestStatusJob, after: Archivematica::TransferStatusJob
    run Archivematica::PackageDetailsJob, after: Archivematica::IngestStatusJob
    # run UnpackDipForDepositJob, after: Archivematica::PackageDetailsJob

    # There will be multiples of this job
    # run Sword::DepositJob, after: Sword::UnpackDipForDepositJob

    # unsure exactly how to do this, cf Dynamic workflows in gush doco
    #   payloads.first[:output][:array_of_deposits_to_prepare].map do | deposit_to_prepare |
    #     run Sword::DepositJob, after: Sword::UnpackDipForDepositJob, params: { deposit: deposit_to_prepare }
    #     run Calm::CreateUpdateJob, after: Sword::UnpackDipForDepositJob, params: { deposit: deposit_to_prepare }
    #   end

    # more ... (calm stuff)
  end
end
