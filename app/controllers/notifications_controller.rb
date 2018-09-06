class NotificationsController < ApplicationController
  def index
    logger.info("---------------------------")
    logger.info("BOX NOTIFICATION RECEIVED")
    logger.info("Event:\t#{params[:event_type]}")
    logger.info("Item Name:\t#{params[:item_name]}")
    logger.info("Item Type:\t#{params[:item_type]}")
    logger.info("Item Id:\t#{params[:item_id]}")
    if params[:event_type] == 'added_collaborator'
      @flow = ReceivePackageWorkflow.create(params)
      flow.start!
    end
    render json:{'note': "Box Notification Received", 'params': params}
  end
end
