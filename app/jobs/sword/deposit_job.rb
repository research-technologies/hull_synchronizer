module Sword
  # SWORD deposit job
  class DepositJob < BaseJob
    attr_reader :sword_api

    # Prepare and perform a single SWORD deposit
    def perform
#      Rails.logger.info("------------------------")
#      Rails.logger.info("DepositJob: in perform")
#      Rails.logger.info("------------------------")
      setup_sword
#      Rails.logger.info("------------------------")
#      Rails.logger.info("DepositJob: set_sword complete")
#      Rails.logger.info("------------------------")
      @response = sword_api.request
#      Rails.logger.info("------------------------")
#      Rails.logger.info("DepositJob: sword_api request complete")
#      Rails.logger.info("------------------------")
      act_on_status
    end

    private

      def setup_sword
        @sword_api = Sword::Api::Work.new(params: payloads.first[:output][:works][params])
      end

      # run the CalmJob if the deposit succeeds
      def act_on_ok
        act_on_calm
      end

      def act_on_calm
 #       Rails.logger.info("------------------------")
 #       Rails.logger.info("DepositJob: act_on_calm called (assume that sword response was ok")
 #       Rails.logger.info("------------------------")
        calm_job_output = calm_job
 #       Rails.logger.info("------------------------")
 #       Rails.logger.info("DepositJob: calm_job complete: calm_job_output #{calm_job_output[:event]}")
 #       Rails.logger.info("------------------------")
        message_text = "#{sword_api.deposit[:content].split('/').last} successfully deposited"
        output(
          event: calm_job_output[:event],
          message: "#{message_text}; #{calm_job_output[:message]}",
          package_id: payloads.first[:output][:package_id],
          works: payloads.first[:output][:works]
        )
        fail! if calm_job_output[:event] == 'failed'
      end
      
      def calm_job
        opts = { params: {}}
        opts[:params][:work_id] = sword_api.deposit[:content].split('/').last
        opts[:params][:calm_metadata] = payloads.first[:output][:works][params][:calm_metadata]
        job = Calm::CreateComponentJob.new(opts)
        job.perform
      end
  end
end
