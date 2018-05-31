# Usage
# ab_in_file = 'test/fixtures/files/AssetBank-export-2018-03-19-15-48-26.csv'
# ab = DataImporter::MapAssetBank.new(ab_in_file)
# ab.generate_file
#
module DataMapper
  class MapAssetBank < MapCSV
    def header
      dm = DataModel.new
      {
        'file' => dm.filename,
        'assetId' => dm.id,
        'att:Title:3' => dm.title,
        'att:Description:4' => dm.description,
        'att:Keywords:701' => dm.keywords,
        'originalFilename' => dm.original_filename,
        'att:Date Created:7' => dm.date_created,
        'dateAdded' => dm.date_added,
        'dateLastModified' => dm.date_modified,
        'addedBy' => dm.depositor,
        'lastModifiedBy' => dm.last_modified_by,
        'size' => dm.file_size,
        'orientation' => dm.orientation,
        'att:Active Status:21' => nil,
        'att:Activation Date:22' => nil,
        'att:Expiry Date:23' => nil,
        'att:Usage Rights:30' => dm.usage_rights,
        'accessLevels' => dm.access_levels,
        'version' => nil,
        'dateLastDownloaded' => nil,
        'att:Creation Status:702' => dm.creation_status,
        'att:Photo Credit:705' => dm.photo_credit,
        'price' => nil,
        'approved' => nil,
        'previewrestricted' => nil,
        'advancedViewing' => nil,
        'author' => nil,
        'code' => nil,
        'expiryDate' => nil,
        'entityName' => nil,
        'relatedAssets' => dm.related_items,
        'childAssets' => nil,
        'parentAssets' => nil
      }.compact
    end

    def to_process
      {
        'file' => 'process_file'
      }
    end

    def process_file(row)
      "#{File.basename(row['file'], ".*")}.#{row['assetId']}#{File.extname(row['file'])}"
    end

  end
end
