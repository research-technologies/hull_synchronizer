module Sword
  # SWORD package deposit job
  class DepositPackageJob < Sword::DepositJob
    
    # Prepare and perform a SWORD package deposit
    def setup_sword
      @sword_api = Sword::Api::Work.new(params: payloads.first[:output][:package])
    end
    
    def act_on_ok
        output(
          event: 'success',
          message: "#{sword_api.deposit[:content].split('/').last} successfully deposited",
          package_id: sword_api.deposit[:content].split('/').last,
          works: payloads.first[:output][:works]
        )
      end
  end
end
