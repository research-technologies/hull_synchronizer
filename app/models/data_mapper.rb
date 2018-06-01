class DataMapper < ApplicationRecord
  FILE_TYPE_OPTIONS = ['Share point', 'Asset bank']
  STATUS = ['Waiting', 'Processing', 'Error', 'Done']
  #Mounts paperclip files
  has_attached_file :original_file
  has_attached_file :mapped_file
  # validations
  validates_inclusion_of :file_type, :in => FILE_TYPE_OPTIONS
  validates_inclusion_of :status, :in => STATUS, :allow_nil => true
  validates_attachment :original_file, content_type: { content_type: ['text/plain', 'text/csv', 'application/vnd.ms-excel']} , message: "is not in CSV format"
  validates_attachment :mapped_file, content_type: { content_type: ['text/plain', 'text/csv', 'application/vnd.ms-excel']}, message: "is not in CSV format"
end
