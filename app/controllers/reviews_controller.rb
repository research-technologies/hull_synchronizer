class ReviewsController < ApplicationController
  before_action :set_review, only: [:show] # , :edit, :update, :destroy]
  attr_reader :client

  # GET /reviews
  # GET /reviews.json
  def index
    @client = Gush::Client.new
    @reviews = client.all_workflows.select {|wf| wf.class == ReviewWorkflow }
  end

  # GET /reviews/1
  # GET /reviews/1.json
  def show
    @review = ReviewWorkflow.find(params[:id])
  end
  
  def retry_review
    @review = ReviewWorkflow.find(params[:id])
    @review.continue
    @review.reload
    respond_to do |format|
      format.html { redirect_to review_path, notice: "Review #{params[:id]} was sent for a retry." }
      format.json { head :no_content }
    end
  end

  # DELETE /reviews/1
  # DELETE /reviews/1.json
  def destroy
    client = Gush::Client.new
    client.destroy_workflow(client.find_workflow(params[:id]))
    respond_to do |format|
      format.html { redirect_to reviews_path, notice: "Review #{params[:id]} was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_review
      @review = ReviewWorkflow.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def review_params
      params.require(:review).permit(:status)
    end
end
