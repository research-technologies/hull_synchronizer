class DataMapper < ApplicationRecord
  FILE_TYPE_OPTIONS = ['Share point', 'Asset bank'].freeze
  STATUS = %w[Waiting Processing Error Done].freeze
  # Mounts paperclip files
  has_attached_file :original_file
  has_attached_file :mapped_file
  # validations
  validates :file_type, inclusion: { in: FILE_TYPE_OPTIONS }
  validates :status, inclusion: { in: STATUS, allow_nil: true }
  # TODO support 'application/vnd.ms-excel'
  validates_attachment :original_file, content_type: { content_type: ['text/plain', 'text/csv'] }, message: 'is not in CSV format'
  validates_attachment :mapped_file, content_type: { content_type: ['text/plain', 'text/csv'] }, message: 'is not in CSV format'
end
