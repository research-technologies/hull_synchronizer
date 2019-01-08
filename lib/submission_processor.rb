require 'fileutils'
require 'csv'
require 'json'
require 'willow_sword'
require 'data_crosswalks/data_archive_model'
require 'file_locations'
require 'submission_helper'

class SubmissionProcessor
  include SubmissionHelper
  attr_reader :params, :source_dir, :row_count, :current_transfer_dir, :accession

  # Class to assemble and prepare data for transfer to archivematica
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
  # 1. Assemble each row into a directory
  #    The directory name is
  #        work1__level1__level2__level3__dirname or
  #        work1__level1__level2__level3
  #    The directory Contains the data dir or file and metadata.json
  # 2. Assemble the package into a directory
  #    The directory name is package
  #    The directory should contain
  #       submissionDocumentation dir
  #       metadata dir
  #       extras dir
  #         If the source directory contains extra files move them to this dir
  #         Could throw error but opted to add to package
  #       data dirs (one for each row)
  # 3. Create bag in transfer location

  def initialize(params:)
    # Need source dir
    @params = params
    @source_dir = params.fetch(:source_dir, nil)
    raise "Source directory not provided" if @source_dir.blank?
    @source_dir = File.join(sanitized_filepath(@source_dir), File::SEPARATOR)
    @dm = ::DataCrosswalks::DataArchiveModel.new
  end

  def process_submission
    assemble_data
    assemble_archival_files
    build_bag
    cleanup(@source_dir, check_empty: false)
  end

  private

  def assemble_data
    @row_count = 0
    metadata_file_path = FileLocations.metadata_file_path(@source_dir)
    ::CSV.foreach(metadata_file_path, headers: true).each do |csv_row|
      next if csv_row.blank?
      row = strip_csv_row(csv_row)
      @row_count += 1
      filename = row.fetch(@dm.filename)
      data_path = get_data_path(filename)
      # create dir
      dirname = get_dirname(data_path, row_count)
      dest_dir = create_data_dir(dirname)
      if is_remote_file?(data_path)
        FileUtils.cp_r(data_path, dest_dir)
      else
        # Move files
        FileUtils.mv(data_path, dest_dir)
      end
      # write metadata
      write_metadata(row, dest_dir)
    end
  end

  def assemble_archival_files
    package_dir = FileLocations.package_dir(@source_dir)
    move_files_file(package_dir)
    move_metadata_file(package_dir)
    move_submission_doc(package_dir)
    move_metadata_dir(package_dir)
    move_extra_files(package_dir)
  end

  def build_bag
    @current_transfer_dir = FileLocations.new_transfer_dir
    WillowSword::BagPackage.new(FileLocations.process_dir(@source_dir), @current_transfer_dir)
  end

  def has_extra_files?
    extra_files.any?
  end

  def get_dirname(data_path, row_count)
    # The directory name is
    #     work1__level1__level2__level3__dirname or
    #     work1__level1__level2__level3
    # Relative path prefixed with work
    dirname = File.join("work#{row_count}", get_relative_path(data_path))
    # Remove file name
    if File.file?(data_path)
      dirname = File.dirname(dirname)
    end
    # trim file separator from string and replace file separator with '__'
    #   right trim File::SEPARATOR from dirname (reverse.chomp.reverse)
    #   left trim File::SEPARATOR from dirname (chomp)
    #   replace all file separators with '__'
    dirname.
      reverse.chomp(File::SEPARATOR).reverse.
      chomp(File::SEPARATOR).
      gsub(File::SEPARATOR, '__')
  end

  def get_relative_path(data_path)
    if is_remote_file?(data_path)
      # remove remote dir name
      relative_path = data_path.sub(FileLocations.remote_dir, '')
    else
      relative_path = data_path.sub(@source_dir, '')
    end
    relative_path.chomp(File::SEPARATOR)
  end

  def create_data_dir(dirname)
    dest_dir = File.join(FileLocations.process_dir(@source_dir), dirname)
    FileUtils.mkdir_p(dest_dir)
    dest_dir
  end

  def write_metadata(row, dest_dir)
    File.open(File.join(dest_dir, 'metadata.json'),"w") do |f|
      @accession = row['accession_number']
      f.write(JSON.pretty_generate(row))
    end
  end

  def move_files_file(dest_dir)
    # Move FILES.csv
    dest_dir = File.join(dest_dir, FileLocations.metadata_dir)
    FileUtils.mkdir_p(dest_dir)
    FileUtils.mv(FileLocations.files_file_path(@source_dir), dest_dir)
  end

  def move_metadata_file(dest_dir)
    # Move DESCRIPTIONS.csv
    dest_dir = File.join(dest_dir, FileLocations.metadata_dir)
    FileUtils.mkdir_p(dest_dir)
    FileUtils.mv(FileLocations.metadata_file_path(@source_dir), dest_dir)
  end

  def move_submission_doc(dest_dir)
    # Move submission documentation dir
    src_dir = File.join(@source_dir, FileLocations.submission_files_dir)
    if File.directory?(src_dir) and !Dir.empty?(src_dir)
      FileUtils.mkdir_p(dest_dir)
      FileUtils.mv(src_dir, dest_dir)
    end
  end

  def move_metadata_dir(dest_dir)
    # Move files from metadata dir
    src_dir = File.join(@source_dir, FileLocations.metadata_dir)
    if File.directory?(src_dir) and !Dir.empty?(src_dir)
      dest_dir = File.join(dest_dir, FileLocations.metadata_dir)
      FileUtils.mkdir_p(dest_dir)
      FileUtils.mv(Dir.glob(File.join(src_dir, '**', '*')), dest_dir)
      cleanup(src_dir)
    end
  end

  def extra_files
    (Dir.glob(File.join(@source_dir, '*')) -
      FileLocations.working_dirs(@source_dir) - FileLocations.archival_dirs(@source_dir))
  end

  def move_extra_files(dest_dir)
    # get relative path
    # create directories and move files to extras dir
    dest_dir = File.join(dest_dir, FileLocations.extras_dir)
    extra_files.each do |fn|
      relative_path = get_relative_path(fn)
      dest = File.join(dest_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.mv(fn, dest)
    end
  end

  def cleanup(src_dir, check_empty: true)
    if check_empty
      Dir.rmdir src_dir if Dir.empty?(src_dir)
    else
      FileUtils.rm_rf src_dir
    end
  end

end

