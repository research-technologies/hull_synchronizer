class NotificationsController < ApplicationController
  protect_from_forgery with: :null_session
  def index
    if params[:event_type] == 'added_collaborator'
      prefix = "#{params[:item_id].gsub(/[^0-9A-Z]/i, '_')}_"
      STDERR.puts "tmp file prefix: #{prefix}"
      files=Dir["/tmp/#{prefix}timestamp"]
      if files.empty?
        tmp_file=make_tmp_file(prefix)
        TransferWorkflowManager.new(params: params)
      else
        check_timestamp(files.first,prefix)
        STDERR.puts("---- IGNORING ADD COLLAB, TOO SOON! ----")
      end
    end
  end

  def make_tmp_file(prefix)
    File.open("/tmp/#{prefix}timestamp", 'w') {|f| f.write(Time.now.utc) }
  end

  def check_timestamp(file,prefix)
    timestamp = DateTime.parse(File.read(file))
    STDERR.puts "timestamp: #{timestamp}, timestamp.utc #{timestamp.utc}, 2 hours ago: #{(Time.now - 120.minutes).utc}"
    if timestamp.utc < (Time.now - 120.minutes).utc
      TransferWorkflowManager.new(params: params)
      # refresh expired timestamp file
      File.delete(file) if File.exist?(file)
      tmp_file=make_tmp_file(prefix)
    end
  end

end
