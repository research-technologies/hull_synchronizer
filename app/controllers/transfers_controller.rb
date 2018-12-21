class TransfersController < ApplicationController
  before_action :set_transfer, only: [:show, :retry_transfer]
  attr_reader :client, :transfer

  # GET /transfers
  def index
    @client = Gush::Client.new
    @transfers = client.all_workflows.select { |wf| wf.class == TransferWorkflow }
  end

  # GET /transfers/1
  def show; end

  # GET /retry_transfer/1
  def retry_transfer
    transfer.continue
    transfer.reload
    respond_to do |format|
      format.html { redirect_to transfer_path, notice: "Transfer #{params[:id]} was sent for a retry." }
      format.json { head :no_content }
    end
  end

  # DELETE /transfers/1
  def destroy
    @client ||= Gush::Client.new
    client.destroy_workflow(client.find_workflow(params[:id]))
    respond_to do |format|
      format.html { redirect_to transfers_path, notice: "Transfer #{params[:id]} was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_transfer
      @transfer = TransferWorkflow.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transfer_params
      params.require(:transfer).permit(:status)
    end
end
