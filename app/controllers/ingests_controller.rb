class IngestsController < ApplicationController
  before_action :set_ingest, only: [:show, :retry_ingest]
  attr_reader :client, :ingest

  # GET /ingests
  def index
    @client = Gush::Client.new
    @ingests = client.all_workflows.select { |wf| wf.class == IngestWorkflow }
  end

  # GET /ingests/1
  def show; end

  # GET /retry_ingest/1
  def retry_ingest
    ingest.continue
    ingest.reload
    respond_to do |format|
      format.html { redirect_to ingest_path, notice: "Ingest #{params[:id]} was sent for a retry." }
      format.json { head :no_content }
    end
  end

  # DELETE /ingests/1
  def destroy
    @client ||= Gush::Client.new
    client.destroy_workflow(client.find_workflow(params[:id]))
    respond_to do |format|
      format.html { redirect_to ingests_path, notice: "Ingest #{params[:id]} was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_ingest
      @ingest = IngestWorkflow.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ingest_params
      params.require(:ingest).permit(:status)
    end
end
