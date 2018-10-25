# Job to start the ingest workflow manager
class StartIngestJob < Gush::Job
  attr_reader :params
  # payloads.first[:output] [Hash] required params are
  #   item_id, item_name, source_dir, number_of_works
  def perform
    @params = {
      item_id: payloads.first[:output][:item_id],
      item_name: payloads.first[:output][:item_name],
      source_dir: payloads.first[:output][:source_dir],
      number_of_works: payloads.first[:output][:number_of_works]
    }
    IngestWorkflowManager.new(params: params)
    build_output
  rescue StandardError => e
    output(
        event: 'failed',
        message: "#{e.message}\n\n#{e.backtrace.join('\n')}",
        item_id: params[:item_id],
        item_name: params[:item_name],
        source_dir: params[:source_dir],
        number_of_works: params[:number_of_works]
        )
    fail!
  end

  private

    def build_output
      output(
        event: 'success',
        message: 'Started ingest workflow manager to manage ingest worklow and monitor it',
        # TODO: What should the output contain here?
        # package: package_payload,
        # works: works_payload
        item_id: params[:item_id],
        item_name: params[:item_name],
        source_dir: params[:source_dir],
        number_of_works: params[:number_of_works]
      )
    end
end
