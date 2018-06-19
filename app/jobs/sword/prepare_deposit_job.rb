module Sword
  # Prepare a single deposit
  class PrepareDepositJob < ActiveJob::Base
    queue_as :sword
    attr_reader :job_status_id
    def perform(job_status_id:, metadata:, files:, model:)
      @job_status_id = job_status_id
    end

    def next_job
      Sword::Sword::DepositJob
    end
  end
end
