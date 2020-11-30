require 'boxr'
require 'tempfile'
require 'file_locations'

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
      # folder_from_id will only get 100 items from a folder
      # folder_items will get them all paged or whatever the limit/offset says to
      # in lieu of page processing down stream we will just use a very big limit
      folder_items = client.folder_items(folder, fields:[], offset:0, limit: ENV['BOX_FILE_LIMIT'])
      
      s_id = get_status_folder(folder_id)
      if path
        current_path = File.join(path, folder.name)
      elsif base_path
        current_path = base_path
      else
        current_path = folder.name
      end
#      folder.item_collection.entries.each do |f|
      folder_items.entries.each do |f|
        if f.type == 'file'
          items[f.id] = File.join(current_path, f.name)
        elsif f.id != s_id
          items = items.merge(list_folder(f.id, path: current_path))
        end
      end
      items
    end

    def file_url(file_id)
      @client.download_file(file_id, follow_redirect: false)
    end

    def inform_user(folder_id, folder_name, status, message, unlink: false)
      s_id = create_status_folder(folder_id)
      box_folder = @client.folder_from_id(folder_id)
      file = Tempfile.new('__package_status.txt')
      file.write(Array(message).join("\n\n"))
      file.rewind
      @client.upload_file(file.path, s_id, name: "__status__#{Time.now.strftime('%FT%H-%M-%S-%N')}.txt")
      file.close
      file.unlink
      rename_folder(box_folder, folder_name, status)
      remove_collaboration(box_folder) if unlink
    end

    def rename_folder(box_folder, folder_name, status)
      new_name = "#{folder_name}__#{status}"
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

    def get_status_folder(folder_id)
      folder = client.folder_from_id(folder_id)
      folder.item_collection.entries.each do |f|
        if f.type == 'folder' and f.name == FileLocations.box_status_dir
          return f.id
        end
      end
      nil
    end

    def create_status_folder(folder_id)
      s_id = get_status_folder(folder_id)
      return s_id unless s_id.nil?
      f = client.create_folder(FileLocations.box_status_dir, folder_id)
      f.id
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
