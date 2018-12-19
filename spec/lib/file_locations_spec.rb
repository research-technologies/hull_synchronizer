require 'file_locations'
RSpec.describe FileLocations do
  ENV['LOCAL_BOX_DIR'] = '/data/box'
  ENV['LOCAL_EFS_DATA_DIR'] = '/data/efs'
  ENV['LOCAL_EFS_TRANSFER_DIR'] = '/data/transfer'
  ENV['BAGS_DIR'] = '/data/bag'
  ENV['RAILS_TMP'] = '/test/tmp'

  it 'defines the local mount point for the box dir' do
    expect(FileLocations.local_box_dir).to eq ENV['LOCAL_BOX_DIR']
  end

  it 'defines the local mount point for the aws efs data dir' do
    expect(FileLocations.remote_dir).to eq ENV['LOCAL_EFS_DATA_DIR']
  end

  it 'defines the local mount point of the aws efs archivematica transfer dir' do
    expect(FileLocations.transfer_dir).to eq ENV['LOCAL_EFS_TRANSFER_DIR']
  end

  it 'defines the name of the status dir used in box' do
    expect(FileLocations.box_status_dir).to eq ('__status')
  end

  it 'defines the name of the new transfer directory' do
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
    it 'returns the default metadata file location' do
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(false)
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(false)
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/DESCRIPTION.csv')
    end

    it 'returns the metadata file path from the metadata directory' do
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(false)
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/metadata/DESCRIPTION.csv')
    end

    it 'returns the default metadata file location' do
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(false)
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/DESCRIPTION.csv')
    end

    it 'returns file from the metadata dir if both are vailable' do
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(true)
      expect(FileLocations.metadata_file_path('tmp')).to eq ('tmp/metadata/DESCRIPTION.csv')
    end
  end

  describe 'Files file path' do
    it 'returns the default location for FILES.csv' do
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(false)
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(false)
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/FILES.csv')
    end

    it 'returns the FILES.csv file path from the metadata directory' do
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(false)
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/metadata/FILES.csv')
    end

    it 'returns the default FILES.csv file path' do
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(false)
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/FILES.csv')
    end

    it 'returns FILES.csv from the metadata dir if both are vailable' do
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(true)
      expect(FileLocations.files_file_path('tmp')).to eq ('tmp/metadata/FILES.csv')
    end
  end

  describe 'metadata files' do
    it 'returns the default location for FILES.csv and DESCRIPTION.csv' do
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(false)
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(false)
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(false)
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(false)
      expect(FileLocations.metadata_files('tmp')).to match_array(['tmp/DESCRIPTION.csv', 'tmp/FILES.csv'])
    end

    it 'returns the FILES.csv and DESCRIPTION.csv file path from the metadata directory' do
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(false)
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(false)
      expect(FileLocations.metadata_files('tmp')).to match_array (['tmp/metadata/DESCRIPTION.csv', 'tmp/metadata/FILES.csv'])
    end

    it 'returns the default FILES.csv and DESCRIPTION.csv file path' do
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(false)
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(false)
      expect(FileLocations.metadata_files('tmp')).to match_array(['tmp/DESCRIPTION.csv', 'tmp/FILES.csv'])
    end

    it 'returns FILES.csv and DESCRIPTION.csv from the metadata dir if both are vailable' do
      allow(File).to receive(:file?).with('tmp/FILES.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/FILES.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/DESCRIPTION.csv').and_return(true)
      allow(File).to receive(:file?).with('tmp/metadata/DESCRIPTION.csv').and_return(true)
      expect(FileLocations.metadata_files('tmp')).to match_array (['tmp/metadata/DESCRIPTION.csv', 'tmp/metadata/FILES.csv'])
    end
  end

  it 'returns the working dirs' do
    expect(FileLocations.working_dirs('tmp')).to match_array (['tmp/__processed_data'])
  end

  it 'returns the bags directory' do
    expect(FileLocations.bags_directory).to eq ('/data/bag')
  end

  it 'returns the temp bags directory' do
    expect(FileLocations.temp_bags_directory).to eq ('/test/tmp')
  end
end
