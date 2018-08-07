class SubmissionProcessor
  require 'json'
  require 'willow_sword'
  require 'data_crosswalks/data_archive_model'
  attr_reader :params, :source_dir, :row_count

  # Class to check, assemble and prepare data for transfer to archivematica
  # Steps are
  # 1. Required files and directories should exist
  # 2. Files listed in FILES.csv should exist and
  #    file size or checksum should match
  # 3. DESCRIPTION.csv should contain 1 or more rows apart from header and
  #    the files or folders mentioned in description.csv should exist
  # 4. Assemble each row into a directory
  #    The directory name is
  #        level1__level2__level3__dirname or
  #        level1__level2__level3__item1
  #    The directory Contains the data dir or file and metadata.json
  # 5. Assemble the package into a directory
  #    The directory name is package
  #    The directory should contain
  #        FILE.csv, DESCRIPTION.csv, submission doc, original excel file
  #    If the source directory contains extra files move them to package
  #    NOTE: Could throw error but opted to add to package
  # 6. Create bag in transfer location
  def initialize(params:)
    # Need source dir
    @params = params
    @source_dir = params.fetch('source_dir', nil)
    @dm = ::DataCrosswalks::DataArchiveModel.new
  end

  def process_submission
    raise 'Required files and directory are missing' unless has_required_files?
    raise 'Data files missing' unless has_listed_files?
    raise 'metadata csv error' unless has_valid_metadata?
    assemble_data
    assemble_package
    build_bag
  end

  def remote_dir
    '/data/source/'
  end

  def transfer_dir
    '/data/transfer/'
  end

  def current_transfer_dir
    # %F - Date in iso format - %Y-%m-%d
    # %N - Nanosecond
    # %3N or %L - milliscond
    Time.now.strftime('%FT%H-%M-%S-%N')
  end

  def metadata_files
    ['FILES.csv', 'DESCRIPTION.csv']
  end

  def excluded_folders
    ['metadata', 'submissionDocumentation']
  end

  def working_dir
    File.join(@source_dir, 'processed_data')
  end

  def package_dir
    File.join(working_dir, 'package')
  end

  private

  def has_required_files?
    has_source_directory? and
    has_remote_direcory? and
    has_transfer_directory? and
    has_metadata_files?
  end

  def has_source_directory?
    return false unless @source_dir
    File.directory?(@source_dir)
  end

  def has_remote_direcory?
    File.directory?(remote_dir)
  end

  def has_transfer_directory?
    File.directory?(transfer_dir)
  end

  def has_metadata_files?
    metadata_files.each do |file_name|
      return false unless File.file?(File.join(@source_dir, file_name)) or
                          File.file?(File.join(@source_dir, 'metadata', file_name))
    end
    true
  end

  # Sanity check to ensure files were transferred
  def has_listed_files?
    # TODO:
    # Parse FILES.csv
    # All files listed in FILES.csv should exist
    # File size or checksum should match
    true
  end

  def has_valid_metadata?
    # Should have 1 or more rows and each row should be valid
    rows = 0
    ::CSV.foreach(metadata_file, headers: true).each do |row|
      rows += 1
      return false unless has_valid_row?(row)
    end
    return false unless rows > 0
    true
  end

  def assemble_data
    @row_count = 0
    ::CSV.foreach(metadata_file, headers: true).each do |row|
      if row.any?
        @row_count += 1
        # create dir
        dirname = get_dirname(row, row_count)
        dest_dir = create_data_dir(dirname)
        # Move files
        FileUtils.mv(data_path(row.fetch(@dm.filename)), dest_dir)
        # write metadata
        write_metadata(row, dest_dir)
      end
    end
  end

  def assemble_package
    unless File.directory?(package_dir)
      FileUtils.mkdir_p(package_dir)
    end
    move_files_file(package_dir)
    move_metadata_file(package_dir)
    move_submission_doc(package_dir)
    move_metadata_dir(package_dir)
    move_extra_files(package_dir)
  end

  def build_bag
    WillowSword::BagPackage.new(working_dir,
      File.join(transfer_dir, current_transfer_dir))
  end

  def has_extra_files?
    extra_files.any?
  end

  def metadata_file
    if File.file?(File.join(@source_dir, 'metadata', 'DESCRIPTION.csv'))
      File.join(@source_dir, 'metadata', 'DESCRIPTION.csv')
    else
      File.join(@source_dir, 'DESCRIPTION.csv')
    end
  end

  def files_file
    if File.file?(File.join(@source_dir, 'metadata', 'FILES.csv'))
      File.join(@source_dir, 'metadata', 'FILES.csv')
    else
      File.join(@source_dir, 'FILES.csv')
    end
  end

  def has_valid_row?(row)
    has_data_file?(row.fetch(@dm.filename, nil)) and
    has_required_fields?(row)
  end

  def has_data_file?(filename)
    return false unless filename
    File.exist?(data_path(filename))
  end

  def has_required_fields?(row)
    #TODO: Add checks for required fields in row
    true
  end

  def data_path(filename)
    if is_remote_file?(filename)
      sanitized_filename(filename)
    else
      File.join(@source_dir, sanitized_filename(filename))
    end
  end

  def is_remote_file?(filename)
    sanitized_filename(filename).start_with? remote_dir
  end

  def sanitized_filename(filename)
    File.join(filename.split(File::SEPARATOR))
  end

  def get_dirname(row, row_count)
    dirname = data_path(row.fetch(@dm.filename))
    if File.file?(dirname)
      # replace file name with file count
      dirname = "work#{row_count}"
    elsif is_remote_file?(row.fetch(@dm.filename))
      # remove remote dir name
      dirname = dirname.sub(remote_dir, '')
    else
      dirname = dirname.sub(@source_dir, '')
    end
    # replace file separator with '__'
    dirname.tr(File::SEPARATOR, '').gsub(File::SEPARATOR, '__')
  end

  def create_data_dir(dirname)
    dest_dir = File.join(working_dir, dirname)
    unless File.directory?(dest_dir)
      FileUtils.mkdir_p(dest_dir)
    end
    dest_dir
  end

  def write_metadata(row, dest_dir)
    File.open(File.join(dest_dir, 'metadata.json'),"w") do |f|
      row_hash =  {}
      row.headers.each {|k| row_hash[k] = row.fetch(k) }
      f.write(JSON.pretty_generate(row_hash))
    end
  end

  def move_files_file(dest_dir)
    # Move FILES.csv
    FileUtils.mv(files_file, dest_dir)
  end

  def move_metadata_file(dest_dir)
    # Move DESCRIPTIONS.csv
    FileUtils.mv(metadata_file, dest_dir)
  end

  def move_submission_doc(dest_dir)
    # Move submission documentation dir
    src_dir = File.join(@source_dir, 'submissionDocumentation')
    if File.directory?(src_dir)
      Dir.glob(File.join(src_dir, '*')).each do |fn|
        FileUtils.mv(fn, dest_dir)
      end
      cleanup(src_dir)
    end
  end

  def move_metadata_dir(dest_dir)
    # Move files from metadata dir
    src_dir = File.join(@source_dir, 'metadata')
    if File.directory?(src_dir)
      Dir.glob(File.join(src_dir, '*')).each do |fn|
        FileUtils.mv(fn, dest_dir)
      end
      cleanup(src_dir)
    end
  end

  def extra_files
    Dir.glob(File.join(@source_dir, '*')) - [working_dir]
  end

  def move_extra_files(dest_dir)
    extra_files.each do |fn|
      FileUtils.mv(fn, dest_dir)
    end
  end

  def cleanup(src_dir, check_empty=true)
    if check_empty and (Dir.entries(src_dir) - %w(. .. )).empty?
      Dir.rmdir src_dir
    else
      Dir.rmdir src_dir
    end
  end

end

