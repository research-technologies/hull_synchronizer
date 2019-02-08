require 'csv'
require 'json'
require 'digest/md5'
require 'data_crosswalks/data_archive_model'
require 'file_locations'
require 'submission_helper'
require 'calm/api'

class SubmissionChecker
  include SubmissionHelper
  attr_reader :params, :source_dir, :row_count, :errors, :status

  # Class to check data for transfer to archivematica
  # The file layout is as follows. The source directory contains
  #   FILE.csv
  #     maybe placed within Metadata dir
  #     Has list of all files in the local directory and their checksum
  #   DESCRIPTION.csv
  #     maybe placed within Metadata dir
  #     Has metadata for each data file or directory
  #   submissionDocumentation dir
  #     Directory containing the original excel file and
  #    other admin files relating to the submission you would like to archive
  #   Data files and directories
  # Steps are
  # 1. Required files and directories should exist
  # 2. Files listed in FILES.csv should exist and
  #    file size or checksum should match
  # 3. DESCRIPTION.csv should contain 1 or more rows apart from header and
  #    the files or folders mentioned in description.csv should exist
  # 4. Each accounted file is moved to a checked dir as the easiest way to l
  def initialize(params:)
    # Need source dir
    @params = params
    @source_dir = params.fetch(:source_dir, nil)
    @dm = ::DataCrosswalks::DataArchiveModel.new
    @errors = []
    @src_files = []
    @checked_files_in_metadata = []
    @checked_files_in_file = []
  end

  def check_submission
    @status = true
    unless has_required_files?
      @status = false
      return
    end
    @status = false unless has_listed_files?
    @status = false unless has_valid_metadata?
    has_unverified_files?
    has_unused_files?
    cleanup(@source_dir, check_empty: false) unless @status
    @status
  end

  private

  def has_required_files?
    has_source_directory? &&
    has_remote_directory? &&
    has_transfer_directory? &&
    has_metadata_files?
  end

  def has_source_directory?
    @errors << "Source directory is not defined" if @source_dir.blank?
    return false if @source_dir.blank?
    @source_dir = File.join(sanitized_filepath(@source_dir), File::SEPARATOR)
    has_dir = File.directory?(@source_dir)
    @errors << "Source directory #{@source_dir} is missing" unless has_dir
    has_dir
  end

  def has_remote_directory?
    remote_dir = FileLocations.remote_dir
    @errors << "Remote directory is not defined" if remote_dir.blank?
    return false if remote_dir.blank?
    has_dir = File.directory?(remote_dir)
    @errors << "Remote directory #{remote_dir} is missing" unless has_dir
    has_dir
  end

  def has_transfer_directory?
    transfer_dir = FileLocations.transfer_dir
    @errors << "Transfer directory is not defined" if transfer_dir.blank?
    return false if transfer_dir.blank?
    has_dir = File.directory?(transfer_dir)
    @errors << "Transfer directory #{transfer_dir} is missing" unless has_dir
    has_dir
  end

  def has_metadata_files?
    files_exist = true
    FileLocations.metadata_files(@source_dir).each do |file_path|
      has_file = File.file?(file_path)
      @errors << "File #{file_path} is missing" unless has_file
      files_exist = files_exist && has_file
    end
    files_exist
  end

  # Checks all files against FILES.csv
  def has_listed_files?
    file_count = 0
    all_valid = true
    files_file_path = FileLocations.files_file_path(@source_dir)
    ::CSV.foreach(files_file_path, headers: true).each do |csv_row|
      next if csv_row.blank?
      # Each file listed in FILES.csv should be valid
      row = strip_csv_row(csv_row)
      file_count += 1
      all_valid = all_valid && has_valid_file?(row, file_count)
    end
    # FILES.csv should have atleast 1 row
    unless file_count > 0
      @errors << "Metadata file #{files_file_path} has no rows"
      all_valid = false
    end
    # There should be no unverified files
    all_valid
  end

  # Check each row of DESCRIPTION.csv
  def has_valid_metadata?
    @row_count = 0
    all_valid = true
    metadata_file_path = FileLocations.metadata_file_path(@source_dir)
    ::CSV.foreach(metadata_file_path, headers: true).each do |csv_row|
      next if csv_row.blank?
      # Each row of metadata listed in DESCRIPTION.csv should be valid
      row = strip_csv_row(csv_row)
      @row_count += 1
      all_valid = all_valid && has_valid_metadata_row?(row, @row_count)
    end
    # Should have 1 or more rows
    unless @row_count > 0
      @errors << "Metadata file #{metadata_file_path} has no rows"
      all_valid = false
    end
    all_valid
  end

  # Check each row of FILES.csv
  def has_valid_file?(row, row_index)
    # Ignore FILES.csv
    filepath = get_data_path(row.fetch('path'))
    return true if filepath.end_with?(FileLocations.files_file_name)
    # the file exists on disk
    return false unless has_file?(filepath, row_index)
    # The file size matches
    has_size = has_required_size?(filepath, row, row_index)
    # The hash matches
    has_hash = has_required_hash?(filepath, row, row_index)
    # Files ias added to list of cheked files
    @checked_files_in_file << filepath
    has_size && has_hash
  end

  def has_valid_metadata_row?(row, row_index)
    filename = row.fetch(@dm.filename, nil)
    has_file = has_data_file?(filename, row_index)
    has_fields = has_required_fields?(row, row_index)
    has_calm_collection = has_calm_collection?(row, row_index)
    add_checked_file(filename)
    has_file && has_fields && has_calm_collection
  end

  # Check file mentioned in FILES.csv exists
  def has_file?(filepath, row_index)
    files_file_path = FileLocations.files_file_path(@source_dir)
    if filepath.blank?
      @errors << "No filename in #{files_file_path}, row #{row_index}"
      return false
    end
    has_file = File.exist?(filepath)
    @errors << "File #{filepath} in #{files_file_path}, row #{row_index} is missing" unless has_file
    has_file
  end

  def has_required_size?(filepath, row, row_index)
    listed_size = row.fetch('file_size', nil).to_i
    file_size = File.size(filepath)
    has_size = false
    # if (0.9*listed_size) <= file_size and file_size <= (1.1*listed_size)
    #   has_size = true
    # end
    has_size = true if file_size == listed_size
    files_file_path = FileLocations.files_file_path(@source_dir)
    @errors << "File #{filepath} in #{files_file_path}, row #{row_index} has file size mismatch with original" unless has_size
    has_size
  end

  def has_required_hash?(filepath, row, row_index)
    listed_hash = row.fetch('checksum', nil)
    current_hash = get_hash(filepath)
    has_hash = false
    has_hash = true if listed_hash == current_hash
    files_file_path = FileLocations.files_file_path(@source_dir)
    @errors << "File #{filepath} in #{files_file_path}, row #{row_index} has file hash mismatch with original" unless has_hash
    has_hash
  end

  def has_data_file?(filename, row_index)
    metadata_file_path = FileLocations.metadata_file_path(@source_dir)
    @errors << "No filename in #{metadata_file_path}, row #{row_index}" if filename.blank?
    return false if filename.blank?
    has_file = File.exist?(get_data_path(filename))
    @errors << "File #{filename} in #{metadata_file_path}, row #{row_index} is missing" unless has_file
    has_file
  end

  def has_required_fields?(row, row_index)
    metadata_file_path = FileLocations.metadata_file_path(@source_dir)
    has_fields = true
    @dm.required_fields.each do |field|
      has_fields = has_fields && row.fetch(field, nil).present?
    end
    @errors << "Required fields error in #{metadata_file_path}, row #{row_index}" unless has_fields
    has_fields
  end

  def has_calm_collection?(row, row_index)
    metadata_file_path = FileLocations.metadata_file_path(@source_dir)
    collection = nil
    has_collection = false
    reference = row.fetch(@dm.reference, nil)
    if reference.blank?
      @errors << "CALM collection reference is missing in #{metadata_file_path}, row #{row_index}"
      return has_collection
    end
    parent = Calm::Api.new.get_record_by_field('RefNo', reference)
    if parent.present? and parent.first != false
      collection = parent.last['RecordID'].join
    end
    unless collection.blank?
      has_collection = true
    else
      @errors << "CALM collection with reference #{reference} in #{metadata_file_path}, row #{row_index} is missing in CALM"
    end
    has_collection
  end

  def add_checked_file(filename)
    unless is_remote_file?(filename)
      data_path = get_data_path(filename)
      @checked_files_in_metadata << data_path
      if File.directory?(data_path)
        @checked_files_in_metadata += Dir.glob(File.join(data_path, '**', '*'))
      end
    end
  end

  # List of local files not mentioned in FILES.csv
  def has_unverified_files?
    unverified_files = submitted_files -
      FileLocations.metadata_files(@source_dir) -
      @checked_files_in_file
    # log error if unverified files exist
    if unverified_files.any?
      files_file_path = FileLocations.files_file_path(@source_dir)
      @errors << "There are files in the submission not listed in #{files_file_path} and so not verified."
      @errors += unverified_files.map { |e| "  - #{e}" }
    end
    unverified_files.any?
  end

  # List of local files not mentioned in DESCRIPTION.csv
  def has_unused_files?
    unused_files = submitted_data_files - @checked_files_in_metadata
    # log error if unused files exist
    if unused_files.any?
      metadata_file_path = FileLocations.metadata_file_path(@source_dir)
      @errors << "There are files in the submission not listed in #{metadata_file_path} and so not used."
      @errors += unused_files.map { |e| "  - #{e}" }
    end
    unused_files.any?
  end

  def submitted_files
    # List all files in source and exclude directory entries
    Dir.glob(File.join(@source_dir, '**', '*')).
      reject { |f| File.directory?(f) }
  end

  def submitted_data_files
    submitted_files -
      # Metadata files are accounted for
      FileLocations.metadata_files(@source_dir) -
      # Entries in metadata directory are accounted for
      Dir.glob(File.join(@source_dir, FileLocations.metadata_dir, '**', '*')) -
      # Entries in submission documentation are accounted for
      Dir.glob(File.join(@source_dir, FileLocations.submission_files_dir, '**', '*'))
  end

  def get_hash(filepath)
    md5 = Digest::MD5.new
    open(filepath, "rb") do |f|
      f.each_chunk { |chunk| md5.update(chunk) }
    end
    md5.hexdigest
  end

end

class File
  def each_chunk(chunk_size = 16384)
    yield read(chunk_size) until eof?
  end
end
