module SubmissionHelper

  private

  def strip_csv_row(unstriped_row)
    row = {}
    unstriped_row.each{|k, v| row[k.strip] = v.strip}
    row
  end

  def get_data_path(filepath)
    return if filepath.blank?
    if is_remote_file?(filepath) or is_local_file?(filepath)
      sanitized_filepath(filepath).chomp(File::SEPARATOR)
    else
      File.join(@source_dir, sanitized_filepath(filepath)).chomp(File::SEPARATOR)
    end
  end

  def is_remote_file?(filename)
    sanitized_filepath(filename).start_with? File.join(FileLocations.remote_dir, File::SEPARATOR)
  end

  def is_local_file?(filename)
    sanitized_filepath(filename).start_with? File.join(@source_dir, File::SEPARATOR)
  end

  def sanitized_filepath(filename)
    # File name could contain either forward slash or back slash
    File.join(filename.strip.split /[\\\/]/)
  end

end

