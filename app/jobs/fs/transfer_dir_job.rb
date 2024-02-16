# Job to download a file from box and save it to disk
require 'fileutils'
require 'file_locations'

module Fs
  class TransferDirJob < Gush::Job
    attr_reader :file_path

    # Download a file
    # @params [Hash] required params {item_id: file_id, relative_path: relative_path_of_file_with_file_name}
    def perform
      transfer_dir
      build_output
      # Need to decide when to retry. See ingest_status as example
    rescue StandardError => e
      # processor.cleanup unless processor.blank?
      output(
        event: 'retry',
        message: ["Failed to download file #{params[:item_name]} sending for retry", e.message],
        )
#      output(
#        event: 'failed',
#        message: ["Failed to download file #{params[:relative_path]}", e.message],
#        )
      fail!
    end

    private

      def transfer_dir
        STDERR.puts "MAKING DIR: #{params[:source_dir]}"
#        FileUtils.mkdir_p(params[:source_dir])
        FileUtils.cp_r(params[:item_path], params[:source_dir]) 
      end

      def build_output

# uncomment to emulate a failed download
#      output(
#        event: 'retry',
#        message: ["PRETEND Failed to download file #{params[:relative_path]} sending for retry"],
#        )

        output(
          event: 'success',
          message: "Downloaded file #{params[:relative_path]}",
          item_id: params[:item_id],
          relative_path: params[:relative_path],
          file_path: @file_path
        )
      end
  end
end
