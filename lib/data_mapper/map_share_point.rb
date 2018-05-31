# Usage
# sp_in_file = 'test/fixtures/files/SharePoint-example-of-export-spreadsheet.csv'
# sp = DataImporter::MapSharePoint.new(sp_in_file)
# sp.generate_file
#
module DataMapper
  class MapSharePoint < MapCSV
    def header
      dm = DataModel.new
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
