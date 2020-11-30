# Unpack the DIP to prepare multiple deposits and calm metadata
require 'box/api'

module Box
  class InformUserJob < ActiveJob::Base
    queue_as :inform_user

    # Processes the submission package
    def perform(params)
      # params need to cointain item_id, item_name, status, message, unlink
      @processor = Box::Api.new
      item_id = params[:item_id]
      item_name = params[:item_name]
      status = params[:status]
      message = params[:message]
      unlink = params.fetch(:unlink, false)
      @processor.inform_user(item_id, item_name, status, message, unlink: unlink)
    rescue Boxr::BoxrError => e
      Rails.logger.error "#{self.class.name} - #{e.to_s}"
    end
  end
end
