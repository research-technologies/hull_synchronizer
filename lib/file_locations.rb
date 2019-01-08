module FileLocations
  class << self
    def local_box_dir
      ENV['LOCAL_BOX_DIR']
    end

    def remote_dir
      ENV['LOCAL_EFS_DATA_DIR']
    end

    def transfer_dir
      ENV['LOCAL_EFS_TRANSFER_DIR']
    end

    def box_status_dir
      '__status'
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

    def process_dir(source_dir)
      File.join(source_dir, '__processed_data')
    end

    def package_dir(source_dir)
      File.join(process_dir(source_dir), 'package')
    end

    def metadata_file_path(source_dir)
      if File.file?(File.join(source_dir, metadata_dir, metadata_file_name))
        File.join(source_dir, metadata_dir, metadata_file_name)
      else
        File.join(source_dir, metadata_file_name)
      end
    end

    def files_file_path(source_dir)
      if File.file?(File.join(source_dir, metadata_dir, files_file_name))
        File.join(source_dir, metadata_dir, files_file_name)
      else
        File.join(source_dir, files_file_name)
      end
    end

    def metadata_files(source_dir)
      [metadata_file_path(source_dir), files_file_path(source_dir)]
    end

    def archival_dirs(source_dir)
      [
        File.join(package_dir(source_dir), metadata_dir),
        File.join(package_dir(source_dir), submission_files_dir)
      ]
    end

    def working_dirs(source_dir)
      [
        process_dir(source_dir)
      ]
    end

    # location of bags prior to submission to the repo
    def bags_directory
      ENV.fetch('BAGS_DIR', 'tmp')
    end

    # location of bag contents prior to bagging
    def temp_bags_directory
      ENV.fetch('RAILS_TMP', 'tmp')
    end
  end

end
