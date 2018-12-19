# Job to download a file from box and save it to disk
require 'fileutils'
require 'box/api'
require 'box/download_file'
require 'file_locations'

module Box
  class TransferFileJob < Gush::Job
    include Box::DownloadFile
    attr_reader :file_path

    # Download a file
    # @params [Hash] required params {item_id: file_id, relative_path: relative_path_of_file_with_file_name}
    def perform
      setup_paths
      transfer_file
      build_output
      # Need to decide when to retry. See ingest_status as example
    rescue StandardError => e
      # processor.cleanup unless processor.blank?
      output(
        event: 'failed',
        message: ["Failed to download file #{params[:relative_path]}", e.message],
        )
      fail!
    end

    private

      def setup_paths
        @file_path = File.join(FileLocations.local_box_dir, params[:relative_path])
        @file_dir = File.dirname(@file_path)
      end

      def transfer_file
        # Get file url from box
        @processor = Box::Api.new()
        file_url = @processor.file_url(params[:item_id])
        # Download file
        downloaded_file = download(file_url)
        # Save file at desired location
        FileUtils.mkdir_p @file_dir
        FileUtils.mv downloaded_file.path, @file_path
      end

      def build_output
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
