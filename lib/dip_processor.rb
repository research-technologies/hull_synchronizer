require 'dip_reader'
require 'willow_sword'
require 'file_locations'

class DIPProcessor

  attr_reader :params, :dip, :dip_id, :bag_key, :package_payload, :works_payload, :work_metadata

  # Processes a DIP from Archivematica and creates a zip
  #   creates one zip per directory in the original deposit
  #   if there is a directory called 'package', the DIP files (eg. METS) are added
  # @params params [Hash], must include:
  #   params[:dip_location]
  #   params[:package_metadata][:dip_uuid]
  def initialize(params:)
    raise('Missing required params: [:dip_location] and [:package_metadata][:dip_uuid] are required') unless params[:dip_location] && params[:package_metadata][:dip_uuid]
    @params = params
    @package_payload = {}
    @works_payload = []
    @dip = DIPReader.new(params[:dip_location])
    @dip_id = params[:package_metadata][:dip_uuid]
    @bag_key = dip_id
  rescue StandardError => e
    raise e
  end

  def process
    process_package
    process_works
  end
  
  def cleanup
    FileUtils.rm_r(src) if Dir.exist?(src)
    FileUtils.rm_r(dst) if Dir.exist?(dst)
  end

  private

    def process_package
      make_locations
      build_package
      build_bag
      build_zip
      package_payload[:file] = { path: "#{dst}.zip", content_type: 'application/zip' }
      package_payload[:hyrax_work_model] = 'Package'
      package_payload[:packaging] = 'http://purl.org/net/sword/package/BagIt'
      cleanup
    end

    def build_package
      dip.package.each do |file|
        FileUtils.cp_r(file, src)
      end
      write_json(params[:package_metadata])
      write_dc
    end

    def process_works
      dip.works.each do |key, value|
        @bag_key = "#{dip_id}_#{key}"
        make_locations
        build_work(value)
        build_bag
        build_zip
        works_payload <<
          {
            file: { path: "#{dst}.zip", content_type: 'application/zip' },
            packaging: 'http://purl.org/net/sword/package/BagIt',
            calm_metadata: work_metadata
          }
        cleanup
      end
    end

    # Build each work:
    #   copy files to destination for zipping
    #   add 'packaged_by_package_name' to metadata.json
    #   write metadata.json to destination
    def build_work(work_files)
      work_files.each do |file|
        next if file.blank?
        if file.end_with? '-metadata.json'
          @work_metadata = JSON.parse(File.read(file))
          work_metadata[:packaged_by_package_name] = dip_id
          write_json(work_metadata)
        else
          FileUtils.cp_r(file, src)
        end
      end
      write_dc
    end

    def build_zip
      WillowSword::ZipPackage.new(dst, "#{dst}.zip").create_zip
    end

    def build_bag
      WillowSword::BagPackage.new(src, dst)
    end

    def src
      File.join(FileLocations.temp_bags_directory, "#{bag_key}_TMP")
    end

    def dst
      File.join(FileLocations.bags_directory, bag_key)
    end

    def make_locations
      FileUtils.mkdir_p(src) unless Dir.exist?(src)
      FileUtils.mkdir_p(dst) unless Dir.exist?(dst)
    end

    def write_json(json_data)
      # Without the line ending, there is a checksum mismatch when the bag is unzipped
      File.open(File.join(src, 'metadata.json'), "w:UTF-8") do |f|
        f.write "#{JSON.pretty_generate(json_data)}\n"
      end
    end

    def write_dc
      File.open(File.join(src, 'metadata.xml'), "w:UTF-8") do |f|
        f.write "#{dc_start}\n<dc:title>#{bag_key}</dc:title>\n#{dc_end}\n"
      end
    end

    def dc_start
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<metadata xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">"
    end

    def dc_end
      '</metadata>'
    end
end
