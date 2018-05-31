class AddAttachmentOriginalFileMappedFileToDataMappers < ActiveRecord::Migration[5.0]
  def self.up
    change_table :data_mappers do |t|
      t.attachment :original_file
      t.attachment :mapped_file
    end
  end

  def self.down
    remove_attachment :data_mappers, :original_file
    remove_attachment :data_mappers, :mapped_file
  end
end
