class IngestsController < ApplicationController
  before_action :set_ingest, only: [:show] # , :edit, :update, :destroy]
  attr_reader :client

  # GET /ingests
  # GET /ingests.json
  def index
    @client = Gush::Client.new
    @ingests = client.all_workflows
  end

  # GET /ingests/1
  # GET /ingests/1.json
  def show
    @ingest = IngestWorkflow.find(params[:id])
  end
  
  def retry
    @ingest = IngestWorkflow.find(params[:id])
    @ingest.continue
    @ingest.reload
    respond_to do |format|
      format.html { redirect_to ingest_path, notice: "Ingest #{params[:id]} was sent for a retry." }
      format.json { head :no_content }
    end
  end

  # GET /ingests/new
  # def new
  #   @ingest = Ingest.new
  # end

  # GET /ingests/1/edit
  # def edit
  # end

  # POST /ingests
  # POST /ingests.json
  # def create
  #   @ingest = Ingest.new(ingest_params)

  #   respond_to do |format|
  #     if @ingest.save
  #       format.html { redirect_to @ingest, notice: 'Ingest was successfully created.' }
  #       format.json { render :show, status: :created, location: @ingest }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @ingest.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PATCH/PUT /ingests/1
  # PATCH/PUT /ingests/1.json
  # def update
  # end

  # DELETE /ingests/1
  # DELETE /ingests/1.json
  def destroy
    client = Gush::Client.new
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
