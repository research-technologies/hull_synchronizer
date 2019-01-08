require 'file_locations'
RSpec.describe FileLocations do

  it 'defines the local mount point for the box dir' do
    allow(ENV).to receive(:[]).with('LOCAL_BOX_DIR').and_return('/data_dir/box')
    allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(false)
    expect(FileLocations.local_box_dir).to eq '/data_dir/box'
  end

  it 'defines the local mount point for the aws efs data dir' do
    allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
    expect(FileLocations.remote_dir).to eq '/data_dir/efs'
  end

  it 'defines the local mount point of the aws efs archivematica transfer dir' do
    allow(ENV).to receive(:[]).with('LOCAL_EFS_TRANSFER_DIR').and_return('/data_dir/transfer')
    expect(FileLocations.transfer_dir).to eq '/data_dir/transfer'
  end

  it 'defines the name of the status dir used in box' do
    expect(FileLocations.box_status_dir).to eq ('__status')
  end

  it 'defines the name of the new transfer directory' do
    allow(ENV).to receive(:[]).with('LOCAL_EFS_TRANSFER_DIR').and_return('/data/transfer')
    expect(FileLocations.new_transfer_dir).to include("/data/transfer/#{Time.now.strftime('%FT%H-%M-%S')}")
  end

  it 'defines the metadata filename' do
    expect(FileLocations.metadata_file_name).to eq ('DESCRIPTION.csv')
  end

  it 'defines the files filename' do
    expect(FileLocations.files_file_name).to eq ('FILES.csv')
  end

  it 'defines the name of the metadata directory' do
    expect(FileLocations.metadata_dir).to eq ('metadata')
  end

  it 'defines the name of the directory containing submission documentation' do
    expect(FileLocations.submission_files_dir).to eq ('submissionDocumentation')
  end

  it 'defines the name of the extras directory' do
    expect(FileLocations.extras_dir).to eq ('extras')
  end

  it 'defines the name of the process directory' do
    expect(FileLocations.process_dir('test')).to eq ('test/__processed_data')
  end

  it 'defines the name of the package directory' do
    expect(FileLocations.package_dir('test')).to eq ('test/__processed_data/package')
  end

  describe 'metadata file path' do
    it 'returns the metadata file path from the metadata directory' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/DESCRIPTION.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt'])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/metadata/DESCRIPTION.csv')
    end

    it 'returns the metadata file path from the metadata directory in mixed case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/Description.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt'])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/metadata/Description.csv')
    end

    it 'returns the metadata file path from the metadata directory in lower case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/description.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt'])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/metadata/description.csv')
    end

    it 'returns the metadata file path from the source directory' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/DESCRIPTION.csv'])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/DESCRIPTION.csv')
    end

    it 'returns the metadata file path from the source directory in mixed case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/Description.csv'])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/Description.csv')
    end

    it 'returns the metadata file path from the source directory in lower case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/description.csv'])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/description.csv')
    end

    it 'returns the metadata file path from the metadata dir if both are available' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/Description.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/description.csv'])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/metadata/Description.csv')
    end

    it 'returns the default metadata file path if no metadata file is found' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt',])
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/DESCRIPTION.csv')
    end
  end

  describe 'Files file path' do
    it 'returns the FILES.csv file path from the metadata directory' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/FILES.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt'])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/metadata/FILES.csv')
    end

    it 'returns the FILES.csv file path from the metadata directory in mixed case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/Files.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt'])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/metadata/Files.csv')
    end

    it 'returns the FILES.csv file path from the metadata directory in lower case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/files.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt'])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/metadata/files.csv')
    end

    it 'returns the FILES.csv file path from the source directory' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/FILES.csv'])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/FILES.csv')
    end

    it 'returns the FILES.csv file path from the source directory in mixed case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/Files.csv'])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/Files.csv')
    end

    it 'returns the FILES.csv file path from the source directory in lower case' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/files.csv'])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/files.csv')
    end

    it 'returns the FILES.csv file path from the metadata dir if both are available' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/Files.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/files.csv'])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/metadata/Files.csv')
    end

    it 'returns the default FILES.csv file path if no metadata file is found' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt',])
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/FILES.csv')
    end
  end

  describe 'metadata files' do
    it 'returns the default location for FILES.csv and DESCRIPTION.csv' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(['tmp/a.txt'])
      expect(FileLocations.metadata_files('tmp')).to match_array(['tmp/DESCRIPTION.csv', 'tmp/FILES.csv'])
    end

    it 'returns the FILES.csv and DESCRIPTION.csv file path from the metadata directory' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/DESCRIPTION.csv', 'tmp/metadata/FILES.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(['tmp/a.txt'])
      expect(FileLocations.metadata_files('tmp')).to match_array (['tmp/metadata/DESCRIPTION.csv', 'tmp/metadata/FILES.csv'])
    end

    it 'returns the default FILES.csv and DESCRIPTION.csv file path' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/DESCRIPTION.csv', 'tmp/FILES.csv'])
      expect(FileLocations.metadata_files('tmp')).to match_array(['tmp/DESCRIPTION.csv', 'tmp/FILES.csv'])
    end

    it 'returns FILES.csv and DESCRIPTION.csv from the metadata dir if both are vailable' do
      allow(Dir).to receive(:glob).with('tmp/metadata/*').and_return(
        ['tmp/metadata/a.txt', 'tmp/metadata/Description.csv', 'tmp/metadata/Files.csv'])
      allow(Dir).to receive(:glob).with('tmp/*').and_return(
        ['tmp/a.txt', 'tmp/DESCRIPTION.csv', 'tmp/FILE.csv'])
      expect(FileLocations.metadata_files('tmp')).to match_array (['tmp/metadata/Description.csv', 'tmp/metadata/Files.csv'])
    end
  end

  it 'returns the working dirs' do
    expect(FileLocations.working_dirs('tmp')).to match_array (['tmp/__processed_data'])
  end

  it 'returns the bags directory' do
    allow(ENV).to receive(:fetch).with('BAGS_DIR', 'tmp').and_return('/data_dir/bag')
    expect(FileLocations.bags_directory).to eq ('/data_dir/bag')
  end

  it 'returns the temp bags directory' do
    allow(ENV).to receive(:fetch).with('RAILS_TMP', 'tmp').and_return('/temp')
    expect(FileLocations.temp_bags_directory).to eq ('/temp')
  end
end
