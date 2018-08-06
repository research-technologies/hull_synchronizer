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

      def act_on_ok
        @message_text = "#{sword_api.deposit[:content].split('/').last} successfully deposited"
        output(
          event: 'success',
          message: message_text,
          package_id: payloads.first[:output][:package_id],
          work_id: sword_api.deposit[:content].split('/').last,
          works: payloads.first[:output][:works]
        )
      end
  end
end
