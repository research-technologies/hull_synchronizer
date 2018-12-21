class WorkflowsController < ApplicationController
  # GET /workflows
  def index
    @client = Gush::Client.new
    # In progress workflows
    @workflows = @client.all_workflows.select { |wf| wf.finished_at.nil? }.sort_by(&:started_at).reverse!
  end
end
