# Usage
# require 'data_crosswalks/map_share_point'
# sp_dm = DataMapper.first
# sp = DataCrosswalks::MapSharePoint.new(sp_dm)
# sp.generate_file
#
require 'data_crosswalks/map_csv'
require 'data_crosswalks/data_archive_model'
module DataCrosswalks
  class MapSharePoint < MapCSV
    def header
      dm = DataArchiveModel.new
      {
        'Name' => dm.filename,
        'Modified' => dm.date_modified,
        'Modified By' => dm.last_modified_by,
        'Classification' => dm.data_classification,
        'IP ownership' => dm.ip_ownership,
        'Created' => dm.date_created,
        'Created By' => dm.depositor,
        'Item Type' => nil,
        'Path' => dm.file_location
      }.compact
    end

    def to_process
      {}
    end

  end
end
