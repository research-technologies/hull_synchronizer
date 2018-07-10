module Sword
  # Perform a single deposit
  class DepositJob < ActiveJob::Base
    queue_as :sword
    attr_reader :job_status_id
    def perform(job_status_id:, deposit_bag_location:, id: nil)
      @job_status_id = job_status_id
    end

    # there will be no next_job
  end
end
