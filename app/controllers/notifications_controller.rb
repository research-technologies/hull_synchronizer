class NotificationsController < ApplicationController
  protect_from_forgery with: :null_session
  def index
    logger.info("---------------------------")
    logger.info("BOX NOTIFICATION RECEIVED")
    logger.info("Event:\t#{params[:event_type]}")
    logger.info("Item Name:\t#{params[:item_name]}")
    logger.info("Item Type:\t#{params[:item_type]}")
    logger.info("Item Id:\t#{params[:item_id]}")
    if params[:event_type] == 'added_collaborator'
      TransferWorkflowManager.new(params: params)
    end
    render json:{'note': "Box Notification Received"}
  end
end
