class CsvCrosswalkJob < ActiveJob::Base
  queue_as :crosswalk
  require 'data_crosswalks/csv_crosswalk'

  def perform(id, file_type)
    DataCrosswalks::CsvCrosswalk.new(id, file_type).run
  end
end
