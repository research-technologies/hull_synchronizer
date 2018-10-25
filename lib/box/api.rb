require 'boxr'
require 'tempfile'

module Box
  class Api
    attr_reader :client
    # ENV file should be filled.

    def initialize
      get_enterprise_token
      initialize_client
    end

    def list_folder(folder_id, path: nil, base_path: nil)
      items = {}
      folder = client.folder_from_id(folder_id)
      if path
        current_path = File.join(path, folder.name)
      elsif base_path
        current_path = base_path
      else
        current_path = folder.name
      end
      folder.item_collection.entries.each do |f|
        if f.type == 'file'
          items[f.id] = File.join(current_path, f.name)
        else
          items = items.merge(list_folder(f.id, path: current_path))
        end
      end
      items
    end

    def file_url(file_id)
      @client.download_file(file_id, follow_redirect: false)
    end

    def inform_user(folder_id, folder_name, status, message, unlink: false)
      box_folder = @client.folder_from_id(folder_id)
      file = Tempfile.new('__package_status.txt')
      file.write(Array(message).join("\n\n"))
      file.rewind
      @client.upload_file(file.path, box_folder, name: "__status__#{Time.now.strftime('%FT%H-%M-%S-%N')}.txt")
      file.close
      file.unlink
      remove_collaboration(box_folder) if unlink
      rename_folder(box_folder, folder_name, status)
    end

    def rename_folder(box_folder, folder_name, status)
      new_name = "#{folder_name}___#{status}"
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

    private

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

  end
end
