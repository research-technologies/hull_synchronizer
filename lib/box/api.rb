require 'boxr'
require 'tempfile'

module Box
  class Api
    attr_reader :client
    # ENV file should be filled.

    def initialize(params)
      get_enterprise_token
      initialize_client
      @params = params
    end

    def receive_package
      folder = folder_from_id(@params[:item_id])
      @original_name = folder.name
      # package should be available in davfs mount of box with the same name
    end

    def inform_user
      box_folder = folder_from_id(@params[:item_id])
      unless @params[:status]
        file = Tempfile.new('__package_status.txt')
        file.write(@params[:message_text].join("\n\n"))
        file.rewind
        upload_file(box_folder, file.path, '__package_status.txt')
        file.close
        file.unlink
      end
      rename_folder(box_folder, status=@params[:status])
    end

    def get_enterprise_token
      @tokens = Boxr::get_enterprise_token(
        enterprise_id: ENV['ENTERPRISE_ID'],
        private_key: File.read(ENV['JWT_SECRET_KEY_PATH']),
        private_key_password: ENV['JWT_SECRET_KEY_PASSWORD'],
        public_key_id: ENV['PUBLIC_KEY_ID'],
        client_id: ENV['CLIENT_ID'],
        client_secret: ENV['CLIENT_SECRET']
      )
    end

    def initialize_client
      @client = Boxr::Client.new(@tokens.access_token)
    end

    def folder_contents(path=nil)
      (not path) ? @client.folder_items(Boxr::ROOT) : @client.folder_items(path)
    end

    def folder_from_id(folder_id)
      @client.folder_from_id(folder_id)
    end

    def rename_folder(box_folder, status)
      if status
        human_status = 'check_passed'
      else
        human_status = 'check_failed'
      end
      new_name = "#{box_folder.name}___#{human_status}"
      puts new_name
      @client.update_folder(box_folder, name: new_name)
    end

    def remove_collaboration(folder)
      collaborations = @client.folder_collaborations(folder)
      collaborations.each do |collaboration|
        if collaboration.type == 'collaboration' && collaboration.accessible_by.login == ENV['APP_USER_EMAIL']
          @client.remove_collaboration(collaboration)
        end
      end
    end

    def user_id
      # for jwt to get id when initialized with oauth
      @client.current_user.id
    end

    def copy_folder(src_box_folder, dest_box_folder)
      dest_folder_name = "#{src_box_folder.name}-#{Time.now.strftime('%FT%H-%M-%S-%N')}"
      @client.copy_folder(
        src_box_folder,
        dest_box_folder,
        name: dest_folder_name)
      dest_folder_name
    end

    def upload_file(box_folder, file, name)
      @client.upload_file(file, box_folder, name: name)
    end

  end
end
