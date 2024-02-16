require 'jstree-rails-4'
require 'file_locations'

class StartsController < ApplicationController
  protect_from_forgery with: :null_session
  def index
     STDERR.puts "LOCAL WORKING DIR: #{FileLocations.local_working_dir}"
     @tree_data={
      core: {
        data: read_dir(FileLocations.local_working_dir)
      } 
    }
    @tree_data
  end

  def start_transfer
    STDERR.puts "STARTING TRANSFER...."
    TransferWorkflowManager.new(params: params)
    redirect_to transfers_path
  end

  def read_dir dir
    Dir.glob("#{dir}/*").each_with_object([]) do |f, a|
      STDERR.puts "F: #{f} A: #{a}"
      item_name = f.gsub(/#{FileLocations.local_working_dir}\//, '')
      item_id = SecureRandom.uuid
      if File.file?(f)
        a << {text: f, data: {item_id:item_id, item_name:item_name, item_path: f}}
      elsif File.directory?(f)
        a << {text: f, data: {item_id:item_id, item_name:item_name, item_path: f}, children: read_dir(f)}
      end
    end
  end

end
