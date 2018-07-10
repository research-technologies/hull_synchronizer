# Unpack the DIP to prepare multiple deposits
class UnpackDipForDepositJob < ActiveJob::Base
    queue_as :processing
    attr_reader :job_status_id
    def perform(job_status_id:, dip_location:, metadata:)
        @job_status_id = job_status_id
    end

    def next_job
        Sword::PrepareDepositJob
    end

end