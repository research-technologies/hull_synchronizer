module DataCrosswalks
  class CsvCrosswalk
    attr_reader :id, :file_type

    def initialize(id, file_type)
      @id = id
      @file_type = file_type
    end

    def run
      @data_mapper = DataMapper.find(@id)
      if @file_type == 'Share point'
        require 'data_crosswalks/map_share_point'
        xw = DataCrosswalks::MapSharePoint.new(@data_mapper)
        xw.generate_file
      elsif @file_type == 'Asset bank'
        require 'data_crosswalks/map_asset_bank'
        xw = DataCrosswalks::MapAssetBank.new(@data_mapper)
        xw.generate_file
      else
        raise 'format not supported'
      end
    end
  end
end
