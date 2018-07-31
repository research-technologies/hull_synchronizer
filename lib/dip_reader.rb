require 'nokogiri'

class DIPReader
  attr_accessor :dip_folder, :content_struct, :package, :works

  # @todo recursive directories for works?
  # Package will be a hash of files, taken from:
  #   objects/package
  #   METS*.xml
  #   processingConfigMCP.xml

  # Works will be an array: 'dir_name' => ['file', 'file'] taken from:
  #   objects\

  def initialize(dip_folder)
    raise("Cannot find DIP folder: #{dip_folder}") unless Dir.exist?(dip_folder)
    @dip_folder = dip_folder
    @content_struct = mets
    @package = package_files
    @works = works_files
  end

  def mets
    mets_file = Dir.glob(File.join(@dip_folder, "METS.*.xml")).first
    raise("Cannot find METS xml file in: #{dip_folder}") unless mets_file && File.exist?(mets_file)
    mets_xml = File.open(mets_file) { |f| Nokogiri::XML(f) }
    mets_xml.at_xpath("mets:mets/mets:structMap/mets:div[@TYPE='Directory']/mets:div[@LABEL='objects' and @TYPE='Directory']")
  end

  def works_files
    objects = {}
    works_folder = content_struct.element_children.map do |el|
      el.attributes['LABEL'].value if el.attributes['TYPE'].value == 'Directory' && !excluded_folders.include?(el.attributes['LABEL'].value)
    end.compact!
    works_folder.each do |work|
      objects[work] = find_paths(work).compact!
    end
    objects
  end

  def excluded_folders
    ['package', 'metadata', 'submissionDocumentation']
  end

  def package_files
    objects = []
    objects << File.join(@dip_folder, "processingMCP.xml")
    objects << Dir.glob(File.join(@dip_folder, "METS.*.xml")).first
    find_paths('package').each { |file| objects << file }
    objects
  end

  def find_file_by_uuid(uuid)
    Dir.glob(File.join(dip_folder, "objects", uuid_to_string(uuid) + "-*")).first if uuid.present?
  end

  def uuid_to_string(uuid)
    uuid.value.sub("file-", "")
  end

  def find_paths(directory)
    div = @content_struct.at_xpath("mets:div[@LABEL='#{directory}']")
    return [] if div.blank?
    div.xpath("mets:div").select { |item| item.at_xpath("mets:fptr/@FILEID") }.map do |i|
      find_file_by_uuid(i.at_xpath("mets:fptr/@FILEID"))
    end
  end
end
