require 'fileutils'
require 'csv'
require 'json'
require 'digest/md5'
require 'data_crosswalks/data_archive_model'
require 'synchronizer_file_locations'

class SubmissionChecker
  include SynchronizerFileLocations
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
    raise "Source diectory not provided" if @source_dir.blank?
    @source_dir = File.join(@source_dir.split(File::SEPARATOR), File::SEPARATOR)
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
    @status = false if has_extra_files?
  end

  def generate_files_file
    # Convenience method for generating the list of files
    list_files_in_source
    csv_file = CSV.open(files_file_path, "wb")
    csv_file << %w(path filename file_size checksum)
    @src_files.each do |filepath|
      next if metadata_files.include? filepath
      relative_path = filepath.sub(@source_dir, '').chomp(File::SEPARATOR)
      size = File.size(filepath)
      md5_hash = get_hash(filepath)
      filename = File.basename(filepath)
      csv_file << [relative_path, filename, size, md5_hash]
    end
    csv_file.close
  end

  private

  def has_required_files?
    has_source_directory? and
    has_remote_directory? and
    has_transfer_directory? and
    has_metadata_files?
  end

  def has_source_directory?
    @errors << "Source directory is not defined" unless @source_dir
    return false unless @source_dir
    has_dir = File.directory?(@source_dir)
    @errors << "Source directory #{@source_dir} is missing" unless has_dir
    has_dir
  end

  def has_remote_directory?
    has_dir = File.directory?(remote_dir)
    @errors << "Remote directory #{remote_dir} is missing" unless has_dir
    has_dir
  end

  def has_transfer_directory?
    has_dir = File.directory?(transfer_dir)
    @errors << "Transfer directory #{transfer_dir} is missing" unless has_dir
    has_dir
  end

  def has_metadata_files?
    files_exist = true
    metadata_files.each do |file_path|
      has_file = File.file?(file_path)
      @errors << "File #{file_path} is missing" unless has_file
      files_exist = files_exist && has_file
    end
    files_exist
  end

  # Sanity check to ensure files were transferred
  def has_listed_files?
    list_files_in_source
    file_count = 0
    # All files listed in FILES.csv should be valid
    all_valid = true
    ::CSV.foreach(files_file_path, headers: true).each do |row|
      file_count += 1
      # has valid row
      all_valid = all_valid and has_valid_file?(row, file_count)
    end
    # FILES.csv should have atleast 1 row
    unless file_count > 0
      @errors << "Metadata file #{files_file_path} has no rows"
      all_valid = false
    end
    # There should be no unverified files
    all_valid and has_unverified_files?
  end

  def list_files_in_source
    # List all files in source and exclude directory entries
    @src_files = Dir.glob(File.join(@source_dir, '**', '*')).
      reject { |f| File.directory?(f) }
  end

  def has_valid_metadata?
    @row_count = 0
    # All rows should be valid
    all_valid = true
    ::CSV.foreach(metadata_file_path, headers: true).each do |row|
      @row_count += 1
      # has valid row
      all_valid = all_valid and has_valid_row?(row, @row_count)
    end
    # Should have 1 or more rows
    unless @row_count > 0
      @errors << "Metadata file #{metadata_file_path} has no rows"
      all_valid = false
    end
    all_valid
  end

  def has_valid_row?(row, row_index)
    filename = row.fetch(@dm.filename, nil)
    has_file = has_data_file?(filename, row_index)
    has_fields = has_required_fields?(row, row_index)
    add_checked_file(filename)
    has_file and has_fields
  end

  def has_data_file?(filename, row_index)
    #TODO: Check checksum against FILES.csv
    @errors << "Filename from row #{row_index} is missing" unless filename
    return false unless filename
    has_file = File.exist?(get_data_path(filename))
    @errors << "File #{filename} in row #{row_index} is missing" unless has_file
    has_file
  end

  def has_required_fields?(row, row_index)
    has_fields = true
    #TODO: Add checks for required fields in row
    @errors << "Required fields error from row #{row_index}" unless has_fields
    has_fields
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

  def has_extra_files?
    extra_files = get_extra_files
    if extra_files.any?
      @errors << "There are extra files in the submission not listed in #{metadata_file_name}"
      @errors += extra_files.map { |e| "  - #{e}" }
    end
    extra_files.any?
  end

  def get_data_path(filename)
    if is_remote_file?(filename) or filename.start_with?(@source_dir)
      sanitized_filename(filename).chomp(File::SEPARATOR)
    else
      File.join(@source_dir, sanitized_filename(filename)).chomp(File::SEPARATOR)
    end
  end

  def is_remote_file?(filename)
    sanitized_filename(filename).start_with? remote_dir
  end

  def sanitized_filename(filename)
    File.join(filename.split(File::SEPARATOR))
  end

  def get_extra_files
    @src_files -
      # checked files are accounted for
      @checked_files_in_metadata -
      # metadata files
      metadata_files -
      # submission files
      Dir.glob(File.join(@source_dir, submission_files_dir, '**', '*')) -
      # metadata diectory files
      Dir.glob(File.join(@source_dir, metadata_dir, '**', '*'))
  end

  def has_valid_file?(row, row_index)
    filepath = row.fetch('path', nil)
    return false if filepath.blank?
    filepath = File.join(@source_dir, filepath)
    @checked_files_in_file << filepath
    has_file = has_local_file?(filepath, row_index)
    has_size = has_required_size?(row, row_index)
    has_hash = has_required_hash?(row, row_index)
    has_file and has_size and has_hash
  end

  def has_local_file?(filename, row_index)
    @errors << "Local file from row #{row_index} is missing" unless filename
    return false unless filename
    has_file = File.exist?(get_data_path(filename))
    @errors << "Local file #{filename} in row #{row_index} is missing" unless has_file
    has_file
  end

  def has_required_size?(row, row_index)
    filename = row.fetch('path', nil)
    listed_size = row.fetch('file_size', nil).to_i
    data_path = get_data_path(filename)
    file_size = File.size(data_path)
    has_size = false
    # if (0.9*listed_size) <= file_size and file_size <= (1.1*listed_size)
    #   has_size = true
    # end
    has_size = true if file_size == listed_size
    @errors << "Local file #{filename} in row #{row_index} has file size mismatch with original" unless has_size
    has_size
  end

  def has_required_hash?(row, row_index)
    filename = row.fetch('path', nil)
    original_hash = row.fetch('checksum', nil)
    data_path = get_data_path(filename)
    current_hash = get_hash(data_path)
    has_hash = false
    if original_hash == current_hash
      has_hash = true
    end
    @errors << "Local file #{filename} in row #{row_index} has file hash mismatch with original" unless has_hash
    has_hash
  end

  def has_unverified_files?
    extra_files = get_unverified_files
    if extra_files.any?
      @errors << "There are extra files in the submission, not listed in #{files_file_name} and so not verified."
      @errors += extra_files.map { |e| "  - #{e}" }
    end
    extra_files.any?
  end

  def get_unverified_files
    @src_files -
      # checked files are accounted for
      @checked_files_in_file -
      # metadata files
      metadata_files -
      # metadata diectory files
      Dir.glob(File.join(@source_dir, metadata_dir, '**', '*'))
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
