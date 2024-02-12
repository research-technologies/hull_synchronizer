class DataMapper < ApplicationRecord
  FILE_TYPE_OPTIONS = ['Share point', 'Asset bank'].freeze
  STATUS = %w[Waiting Processing Error Done].freeze
  # Mounts paperclip files
  has_one_attached :original_file
  has_one_attached :mapped_file
  # validations
  validates :file_type, inclusion: { in: FILE_TYPE_OPTIONS }
  validates :status, inclusion: { in: STATUS, allow_nil: true }
  # TODO support 'application/vnd.ms-excel'
  validates :original_file, attached: true, content_type: { in: ['text/plain', 'text/csv'], message: 'is not a CSV' } 
  validates :mapped_file, content_type: { in: ['text/plain', 'text/csv'], message: 'is not a CSV' }
end
