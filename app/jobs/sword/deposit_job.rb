module Sword
  # SWORD deposit job
  class DepositJob < BaseJob
    attr_reader :sword_api

    # Prepare and perform a single SWORD deposit
    def perform
      setup_sword
      @response = sword_api.request
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
        calm_job = CalmJob.perform(sword_api.deposit[:content].split('/').last)
        @message_text = "#{sword_api.deposit[:content].split('/').last} successfully deposited"
        output(
          event: calm_job[:event],
          message: "#{message_text}; #{calm_job[:message]}",
          package_id: payloads.first[:output][:package_id],
          works: payloads.first[:output][:works]
        )
        fail! if calm_job[:event] == 'failed'
      end
  end
end
