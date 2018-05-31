class DataMapper < ApplicationRecord
  FILE_TYPE_OPTIONS = ['Share point', 'Asset bank']
  #Mounts paperclip files
  has_attached_file :original_file
  has_attached_file :mapped_file
  # validations
  validates :file_type, presence: true
  validates_attachment :original_file, content_type: { content_type: ['text/csv', 'application/vnd.ms-excel']} , message: "is not in CSV format"
  validates_attachment :mapped_file, content_type: { content_type: ['text/csv', 'application/vnd.ms-excel']}, message: "is not in CSV format"
end
