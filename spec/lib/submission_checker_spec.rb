require 'submission_checker'
RSpec.describe SubmissionChecker do

  describe 'Initialize with source dir' do
    it 'needs params' do
      expect{ SubmissionChecker.new() }.to raise_error(ArgumentError, 'missing keyword: params')
    end
    it 'needs source_dir' do
      expect{ SubmissionChecker.new({ params: {} }) }.not_to raise_error
    end
  end

  describe 'it sets attributes to read' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
    end
    it 'has status' do
      expect(@sc.status).to be_nil
      expect(@sc.params).to eq ({source_dir: 'test'})
      expect(@sc.errors).to eq ([])
      expect(@sc.row_count).to be_nil
    end
  end

  describe 'check_submission' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(@sc).to receive(:has_required_files?).and_return(true)
      allow(@sc).to receive(:has_listed_files?).and_return(true)
      allow(@sc).to receive(:has_valid_metadata?).and_return(true)
      allow(@sc).to receive(:has_unverified_files?).and_return(false)
      allow(@sc).to receive(:has_unused_files?).and_return(false)
    end
    it 'has a status of false if it does not have all the required files' do
      allow(@sc).to receive(:has_required_files?).and_return(false)
      @sc.check_submission
      expect(@sc.status).to eq false
      expect(@sc.errors).to eq []
    end
    it 'has a status of false if it does not have all the listed files' do
      allow(@sc).to receive(:has_listed_files?).and_return(false)
      @sc.check_submission
      expect(@sc.status).to eq false
      expect(@sc.errors).to eq []
    end
    it 'has a status of false if it does not have valid metadata' do
      allow(@sc).to receive(:has_valid_metadata?).and_return(false)
      @sc.check_submission
      expect(@sc.status).to eq false
      expect(@sc.errors).to eq []
    end
    it 'has a status of false if it has unverified files' do
      allow(@sc).to receive(:has_unverified_files?).and_return(true)
      @sc.check_submission
      expect(@sc.status).to eq false
      expect(@sc.errors).to eq []
    end
    it 'has a status of false if it has unused files' do
      allow(@sc).to receive(:has_unused_files?).and_return(true)
      @sc.check_submission
      expect(@sc.status).to eq false
      expect(@sc.errors).to eq []
    end
    it 'has a status of true if it has all the required files, listed files,
      valid metadata, no unverified files and no unused files' do
      @sc.check_submission
      expect(@sc.status).to eq true
      expect(@sc.errors).to eq []
    end
  end

  describe 'has_required_files?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(@sc).to receive(:has_source_directory?).and_return(true)
      allow(@sc).to receive(:has_remote_directory?).and_return(true)
      allow(@sc).to receive(:has_transfer_directory?).and_return(true)
      allow(@sc).to receive(:has_metadata_files?).and_return(true)
    end
    it 'returns false if source directory does not exist' do
      allow(@sc).to receive(:has_source_directory?).and_return(false)
      expect(@sc.send(:has_required_files?)).to eq false
    end
    it 'returns false if remote directory does not exist' do
      allow(@sc).to receive(:has_remote_directory?).and_return(false)
      expect(@sc.send(:has_required_files?)).to eq false
    end
    it 'returns false if transfer directory does not exist' do
      allow(@sc).to receive(:has_transfer_directory?).and_return(false)
      expect(@sc.send(:has_required_files?)).to eq false
    end
    it 'returns false if metadata files do not exist' do
      allow(@sc).to receive(:has_metadata_files?).and_return(false)
      expect(@sc.send(:has_required_files?)).to eq false
    end
    it 'returns true if source directory, remote directory, transfer directory and metadata files exist' do
      expect(@sc.send(:has_required_files?)).to eq true
    end
  end

  describe 'has_source_directory?' do
    it 'returns false if the source directory is blank' do
      @sc = SubmissionChecker.new({ params: {source_dir: ' '} })
      expect(@sc.send(:has_source_directory?)).to eq false
      expect(@sc.errors).to eq (['Source directory is not defined'])
    end
    it 'returns false if the source directory does not exist' do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(File).to receive(:directory?).with('test/').and_return(false)
      expect(@sc.send(:has_source_directory?)).to eq false
      expect(@sc.errors).to eq (['Source directory test/ is missing'])
    end
    it 'returns true if source directory exists' do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(File).to receive(:directory?).with('test/').and_return(true)
      expect(@sc.send(:has_source_directory?)).to eq true
      expect(@sc.errors).to eq ([])
    end
    it 'sanitizes the name and path of the source directory' do
      @sc = SubmissionChecker.new({ params: {source_dir: ' \test\b a/b/ '} })
      allow(File).to receive(:directory?).with('/test/b a/b/').and_return(true)
      expect(@sc.send(:has_source_directory?)).to eq true
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'has_remote_directory?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(FileLocations).to receive(:remote_dir).and_return('test')
    end
    it 'returns false if the remote directory is blank' do
      allow(FileLocations).to receive(:remote_dir).and_return(nil)
      expect(@sc.send(:has_remote_directory?)).to eq false
      expect(@sc.errors).to eq (['Remote directory is not defined'])
    end
    it 'returns false if the remote directory does not exist' do
      allow(File).to receive(:directory?).with('test').and_return(false)
      expect(@sc.send(:has_remote_directory?)).to eq false
      expect(@sc.errors).to eq (['Remote directory test is missing'])
    end
    it 'returns true if a remote directory exists' do
      allow(File).to receive(:directory?).with('test').and_return(true)
      expect(@sc.send(:has_remote_directory?)).to eq true
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'has_transfer_directory?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(FileLocations).to receive(:transfer_dir).and_return('test')
    end
    it 'returns false if the transfer directory is blank' do
      allow(FileLocations).to receive(:transfer_dir).and_return(nil)
      expect(@sc.send(:has_transfer_directory?)).to eq false
      expect(@sc.errors).to eq (['Transfer directory is not defined'])
    end
    it 'returns false if the transfer directory does not exist' do
      allow(File).to receive(:directory?).with('test').and_return(false)
      expect(@sc.send(:has_transfer_directory?)).to eq false
      expect(@sc.errors).to eq (['Transfer directory test is missing'])
    end
    it 'returns true if a transfer directory exists' do
      allow(File).to receive(:directory?).with('test').and_return(true)
      expect(@sc.send(:has_transfer_directory?)).to eq true
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'has_metadata_files?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(FileLocations).to receive(:metadata_files).with('test').
        and_return(['test/DESCRIPTION.csv','test/FILES.csv'])
      allow(File).to receive(:file?).with('test/DESCRIPTION.csv').and_return(true)
      allow(File).to receive(:file?).with('test/FILES.csv').and_return(true)
    end
    it 'returns false if DESCRIPTION.csv does not exist' do
      allow(File).to receive(:file?).with('test/DESCRIPTION.csv').and_return(false)
      expect(@sc.send(:has_metadata_files?)).to eq false
      expect(@sc.errors).to eq (['File test/DESCRIPTION.csv is missing'])
    end
    it 'returns false if FILES.csv does not exist' do
      allow(File).to receive(:file?).with('test/FILES.csv').and_return(false)
      expect(@sc.send(:has_metadata_files?)).to eq false
      expect(@sc.errors).to eq (['File test/FILES.csv is missing'])
    end
    it 'returns false if DESCRIPTION.csv and FILES.csv does not exist' do
      allow(File).to receive(:file?).with('test/DESCRIPTION.csv').and_return(false)
      allow(File).to receive(:file?).with('test/FILES.csv').and_return(false)
      expect(@sc.send(:has_metadata_files?)).to eq false
      expect(@sc.errors).to match_array(['File test/DESCRIPTION.csv is missing',
        'File test/FILES.csv is missing'])
    end
    it 'returns true if DESCRIPTION.csv and FILES.csv exist' do
      expect(@sc.send(:has_metadata_files?)).to eq true
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'has_listed_files?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"path"=>"snow-cap.jpg", "filename"=>"snow-cap.jpg", "file_size"=>"2648158", "checksum"=>"b06ae9acfa487e0da66a57ec209176a4"},
        {"path"=>"README.txt", "filename"=>"README.txt", "file_size"=>"359", "checksum"=>"6d4cdce81f0d3e07f8f3e9caaea5fc21"},
        {"path"=>"DESCRIPTION.csv", "filename"=>"DESCRIPTION.csv", "file_size"=>"67", "checksum"=>"2885e7fcb1c7995922342aa3650cf6a6"}
      ]
      allow(@sc).to receive(:has_valid_file?).with(@rows[0], 1).and_return(true)
      # allow(@sc).to receive(:has_valid_file?).with(@rows[1], 2).and_return(true)
      allow(@sc).to receive(:has_valid_file?).with(@rows[2], 3).and_return(true)
    end
    it 'checks FILES.csv to have 1 or more rows' do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test2'} })
      expect(@sc.send(:has_listed_files?)).to eq false
      msg = 'Metadata file spec/fixtures/files/submission/test2/FILES.csv has no rows'
      expect(@sc.errors).to eq ([msg])
    end
    it 'returns true if all rows are valid' do
      allow(@sc).to receive(:has_valid_file?).with(@rows[1], 2).and_return(true)
      expect(@sc.send(:has_listed_files?)).to eq true
      expect(@sc.errors).to eq ([])
    end
    it 'returns false if one or more rows are invalid' do
      allow(@sc).to receive(:has_valid_file?).with(@rows[1], 2).and_return(false)
      expect(@sc.send(:has_listed_files?)).to eq false
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'has_valid_metadata?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"filename"=>"snow-cap.jpg", "accession_number"=>"20181218/1", "reference"=>"U TEST"},
        {"filename"=>"README.txt", "accession_number"=>"20181218/2", "reference"=>"U TEST"}
      ]
      allow(@sc).to receive(:has_valid_metadata_row?).with(@rows[0], 1).and_return(true)
    end
    it 'checks DESCRIPTION.csv to have 1 or more rows' do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test2'} })
      expect(@sc.send(:has_valid_metadata?)).to eq false
      msg = 'Metadata file spec/fixtures/files/submission/test2/DESCRIPTION.csv has no rows'
      expect(@sc.errors).to eq ([msg])
    end
    it 'returns true if all rows are valid' do
      allow(@sc).to receive(:has_valid_metadata_row?).with(@rows[1], 2).and_return(true)
      expect(@sc.send(:has_valid_metadata?)).to eq true
      expect(@sc.errors).to eq ([])
    end
    it 'returns false if one or more rows are invalid' do
      allow(@sc).to receive(:has_valid_metadata_row?).with(@rows[1], 2).and_return(false)
      expect(@sc.send(:has_valid_metadata?)).to eq false
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'has_valid_file?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"path"=>"FILES.csv", "filename"=>"FILES.csv", "file_size"=>"6798", "checksum"=>"2885e7"},
        {"path"=>"new_file.txt", "filename"=>"new_file.txt", "file_size"=>"67658", "checksum"=>"2885e7"}
      ]
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
    end
    it 'returns true if file is FILES.csv without doing checks' do
      expect(@sc.send(:has_valid_file?, @rows[0], 1)).to eq true
      expect(@sc.errors).to eq ([])
    end
    it 'returns false if file does not exist' do
      allow(@sc).to receive(:has_file?).with('spec/fixtures/files/submission/test1/new_file.txt', 1).and_return(false)
      expect(@sc.send(:has_valid_file?, @rows[1], 1)).to eq false
      expect(@sc.errors).to eq ([])
    end
    it 'returns false if file size is not equal' do
      path = 'spec/fixtures/files/submission/test1/new_file.txt'
      allow(@sc).to receive(:has_file?).with(path, 1).and_return(true)
      allow(@sc).to receive(:has_required_size?).with(path, @rows[1], 1).and_return(false)
      allow(@sc).to receive(:has_required_hash?).with(path, @rows[1], 1).and_return(true)
      expect(@sc.send(:has_valid_file?, @rows[1], 1)).to eq false
      expect(@sc.errors).to eq ([])
    end
    it 'returns false if file hash is not equal' do
      path = 'spec/fixtures/files/submission/test1/new_file.txt'
      allow(@sc).to receive(:has_file?).with(path, 1).and_return(true)
      allow(@sc).to receive(:has_required_size?).with(path, @rows[1], 1).and_return(true)
      allow(@sc).to receive(:has_required_hash?).with(path, @rows[1], 1).and_return(false)
      expect(@sc.send(:has_valid_file?, @rows[1], 1)).to eq false
      expect(@sc.errors).to eq ([])
    end
    it 'returns true if file size and hash are equal' do
      path = 'spec/fixtures/files/submission/test1/new_file.txt'
      allow(@sc).to receive(:has_file?).with(path, 1).and_return(true)
      allow(@sc).to receive(:has_required_size?).with(path, @rows[1], 1).and_return(true)
      allow(@sc).to receive(:has_required_hash?).with(path, @rows[1], 1).and_return(true)
      expect(@sc.send(:has_valid_file?, @rows[1], 1)).to eq true
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'has_valid_metadata_row?' do
    let(:calm_api) { instance_double(Calm::Api) }
    # has_file = has_data_file?(filename, row_index)
    # has_fields = has_required_fields?(row, row_index)
    # has_calm_collection = has_calm_collection?(row, row_index)
    # add_checked_file(filename)
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"filename"=>"snow-cap.jpg", "accession_number"=>"20181218/1", "reference"=>"U TEST"},
        {"filename"=>"README.txt", "accession_number"=>"", "reference"=>"U TEST"},
        {"filename"=>"NoFile.txt", "accession_number"=>"20181218/2", "reference"=>"U TEST"},
      ]
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
    end
    it 'returns true if the metadata row has the file, the required fields and the calm collection' do
      allow(@sc).to receive(:has_calm_collection?).with(@rows[0], 1).and_return true
      expect(@sc).to receive(:add_checked_file).with('snow-cap.jpg')
      expect(@sc.send(:has_valid_metadata_row?, @rows[0], 1)).to eq true
    end
    it 'returns false if the metadata row does not have the calm collection' do
      allow(@sc).to receive(:has_calm_collection?).with(@rows[0], 1).and_return false
      expect(@sc).to receive(:add_checked_file).with('snow-cap.jpg')
      expect(@sc.send(:has_valid_metadata_row?, @rows[0], 1)).to eq false
    end
    it 'returns false if the metadata row does not have the file' do
      allow(@sc).to receive(:has_calm_collection?).with(@rows[2], 3).and_return true
      expect(@sc).to receive(:add_checked_file).with('NoFile.txt')
      expect(@sc.send(:has_valid_metadata_row?, @rows[2], 3)).to eq false
    end
    it 'returns false if the metadata row does not have the required fields' do
      allow(@sc).to receive(:has_calm_collection?).with(@rows[1], 2).and_return true
      expect(@sc).to receive(:add_checked_file).with('README.txt')
      expect(@sc.send(:has_valid_metadata_row?, @rows[1], 2)).to eq false
    end
  end

  describe 'has_file?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
    end
    it 'returns true if the file exists' do
      filepath = 'spec/fixtures/files/submission/test1/snow-cap.jpg'
      expect(@sc.send(:has_file?, filepath, 1)).to eq true
    end
    it 'returns true if the directory exists' do
      filepath = 'spec/fixtures/files/calm'
      expect(@sc.send(:has_file?, filepath, 2)).to eq true
    end
    it 'returns false if the directory does not exists' do
      filepath = 'spec/fixtures/files/test123'
      expect(@sc.send(:has_file?, filepath, 1)).to eq false
      expect(@sc.errors).to eq (["File #{filepath} in row 1 is missing in spec/fixtures/files/submission/test1/FILES.csv"])
    end
  end
end
