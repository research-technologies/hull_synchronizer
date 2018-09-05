module SynchronizerFileLocations

  def remote_dir
    '/data/source/'
  end

  def transfer_dir
    '/data/transfer/'
  end

  def new_transfer_dir
    # %F - Date in iso format - %Y-%m-%d
    # %N - Nanosecond
    # %3N or %L - milliscond
    File.join(transfer_dir, Time.now.strftime('%FT%H-%M-%S-%N'))
  end

  def metadata_file_name
    'DESCRIPTION.csv'
  end

  def files_file_name
    'FILES.csv'
  end

  def metadata_dir
    'metadata'
  end

  def submission_files_dir
    'submissionDocumentation'
  end

  def extras_dir
    'extras'
  end

  def process_dir
    File.join(@source_dir, '__processed_data')
  end

  def metadata_file_path
    if File.file?(File.join(@source_dir, metadata_dir, metadata_file_name))
      File.join(@source_dir, metadata_dir, metadata_file_name)
    else
      File.join(@source_dir, metadata_file_name)
    end
  end

  def files_file_path
    if File.file?(File.join(@source_dir, metadata_dir, files_file_name))
      File.join(@source_dir, metadata_dir, files_file_name)
    else
      File.join(@source_dir, files_file_name)
    end
  end

  def metadata_files
    [metadata_file_path, files_file_path]
  end

  def archival_dirs
    [
      File.join(@source_dir, metadata_dir),
      File.join(@source_dir, submission_files_dir)
    ]
  end

  def working_dirs
    [
      process_dir
    ]
  end
end
