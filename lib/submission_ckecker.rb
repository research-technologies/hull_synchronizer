require 'fileutils'
require 'csv'
require 'json'
require 'willow_sword'
require 'data_crosswalks/data_archive_model'
require 'synchronizer_file_locations'

class SubmissionChecker
  include SynchronizerFileLocations
  attr_reader :params, :source_dir, :row_count, :errors

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
    @source_dir = @source_dir.chomp(File::SEPARATOR) unless @source_dir.blank?
    @dm = ::DataCrosswalks::DataArchiveModel.new
    @errors = []
    @src_files = []
    @checked_files = []
  end

  def check_submission
    raise 'Required files and directory are missing' unless has_required_files?
    raise 'File transfer error' unless has_listed_files?
    raise 'metadata error' unless has_valid_metadata?
    raise 'extra files error' if has_extra_files?
    true
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
    @src_files = Dir.glob(File.join(@source_dir, '**', '*'))
    # TODO: Parse FILES.csv
    # All files listed in FILES.csv should exist
    # File size or checksum should match
    true
  end

  def has_valid_metadata?
    # Should have 1 or more rows and each row should be valid
    row_count = 0
    # All rows should be valid
    all_valid = true
    ::CSV.foreach(metadata_file_path, headers: true).each do |row|
      row_count += 1
      # has valid row
      all_valid = all_valid and has_valid_row?(row, row_count)
    end
    @errors << "metadata file #{metadata_file_path} has no rows" unless row_count > 0
    return false unless row_count > 0
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
      @checked_files << data_path
      if File.directory?(data_path)
        @checked_files += Dir.glob(File.join(data_path, '**', '*'))
      end
    end
  end

  def has_extra_files?
    extra_files = get_extra_files
    if extra_files.any?
      msg = "There are extra files in the submission.\n"
      msg += "  " + extra_files.join("\n  ")
      @errors << msg
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
    (@src_files -
      # checked files are accounted for
      @checked_files -
      # metadata files
      metadata_files -
      # submission files
      Dir.glob(File.join(@source_dir, submission_files_dir, '**', '*')) -
      # metadata diectory files
      Dir.glob(File.join(@source_dir, metadata_dir, '**', '*'))).
      # Interested only in list of files, not directory entries
      reject { |f| File.directory?(f) }
  end

end

