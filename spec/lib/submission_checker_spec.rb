require 'submission_checker'
RSpec.describe SubmissionChecker do
  let(:calm_class) {class_double(Calm::Api)}
  let(:calm_api) { instance_double(Calm::Api) }

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
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/'} })
    end
    it 'returns true if the file exists' do
      filepath = 'spec/fixtures/files/submission/test1/snow-cap.jpg'
      expect(@sc.send(:has_file?, filepath, 1)).to eq true
    end
    it 'returns true if the directory exists' do
      filepath = 'spec/fixtures/files/submission/test2'
      expect(@sc.send(:has_file?, filepath, 2)).to eq true
    end
    it 'returns false if the directory does not exists' do
      filepath = 'spec/fixtures/files/submission/test123'
      expect(@sc.send(:has_file?, filepath, 1)).to eq false
      expect(@sc.errors).to eq (["File #{filepath} in spec/fixtures/files/submission/FILES.csv, row 1 is missing"])
    end
    it 'returns false if the filename is blank' do
      expect(@sc.send(:has_file?, '', 1)).to eq false
      expect(@sc.errors).to eq (["No filename in spec/fixtures/files/submission/FILES.csv, row 1"])
    end
  end

  describe 'has_required_size?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"path"=>"snow-cap.jpg", "filename"=>"snow-cap.jpg", "file_size"=>"221193", "checksum"=>"93d7c1702e662083ae3083f452b7a472"},
        {"path"=>"README.txt", "filename"=>"README.txt", "file_size"=>"359", "checksum"=>"6d4cdce81f0d3e07f8f3e9caaea5fc21"}
      ]
    end
    it 'returns true if the file size matches' do
      filepath = 'spec/fixtures/files/submission/test1/snow-cap.jpg'
      expect(@sc.send(:has_required_size?, filepath, @rows[0], 1)).to eq true
      expect(@sc.errors).to eq ([])
    end
    it 'returns false if the row does not have file size' do
      filepath = 'spec/fixtures/files/submission/test1/snow-cap.jpg'
      allow(@rows[0]).to receive(:fetch).with('file_size', nil).and_return nil
      allow(File).to receive(:size).with(filepath).and_return 221193
      expect(@sc.send(:has_required_size?, filepath, @rows[0], 1)).to eq false
      expect(@sc.errors).to eq (["File #{filepath} in spec/fixtures/files/submission/test1/FILES.csv, row 1 has file size mismatch with original"])
    end
    it 'returns false if the file sizes do not match' do
      filepath = 'spec/fixtures/files/submission/test1/README.txt'
      expect(@sc.send(:has_required_size?, filepath, @rows[0], 1)).to eq false
      expect(@sc.errors).to eq (["File #{filepath} in spec/fixtures/files/submission/test1/FILES.csv, row 1 has file size mismatch with original"])
    end
  end

  describe 'has_required_hash?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"path"=>"snow-cap.jpg", "filename"=>"snow-cap.jpg", "file_size"=>"221193", "checksum"=>"93d7c1702e662083ae3083f452b7a472"},
        {"path"=>"README.txt", "filename"=>"README.txt", "file_size"=>"359", "checksum"=>"6d4cdce"}
      ]
    end
    it 'returns true if the file hash matches' do
      filepath = 'spec/fixtures/files/submission/test1/snow-cap.jpg'
      expect(@sc.send(:has_required_hash?, filepath, @rows[0], 1)).to eq true
      expect(@sc.errors).to eq ([])
    end
    it 'returns false if the row does not have file hash' do
      filepath = 'spec/fixtures/files/submission/test1/snow-cap.jpg'
      allow(@rows[0]).to receive(:fetch).with('checksum', nil).and_return nil
      allow(@sc).to receive(:get_hash).with(filepath).and_return '93d7c1702e662083ae3083f452b7a472'
      expect(@sc.send(:has_required_hash?, filepath, @rows[0], 1)).to eq false
      expect(@sc.errors).to eq (["File #{filepath} in spec/fixtures/files/submission/test1/FILES.csv, row 1 has file hash mismatch with original"])
    end
    it 'returns false if the file hashes do not match' do
      filepath = 'spec/fixtures/files/submission/test1/README.txt'
      expect(@sc.send(:has_required_hash?, filepath, @rows[0], 1)).to eq false
      expect(@sc.errors).to eq (["File #{filepath} in spec/fixtures/files/submission/test1/FILES.csv, row 1 has file hash mismatch with original"])
    end
  end

  describe 'has_data_file?' do
    before(:each) do
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission'} })
    end
    it 'returns true if the file exists' do
      filepath = 'spec/fixtures/files/submission/test1/snow-cap.jpg'
      expect(@sc.send(:has_data_file?, filepath, 1)).to eq true
    end
    it 'returns true if the directory exists' do
      filepath = 'spec/fixtures/files/submission/test2'
      expect(@sc.send(:has_data_file?, filepath, 2)).to eq true
    end
    it 'returns false if the directory does not exists' do
      filepath = 'spec/fixtures/files/submission/test123'
      expect(@sc.send(:has_data_file?, filepath, 1)).to eq false
      expect(@sc.errors).to eq (["File #{filepath} in spec/fixtures/files/submission/DESCRIPTION.csv, row 1 is missing"])
    end
    it 'returns false if the filename does not exists' do
      expect(@sc.send(:has_data_file?, '', 1)).to eq false
      expect(@sc.errors).to eq (["No filename in spec/fixtures/files/submission/DESCRIPTION.csv, row 1"])
    end
  end

  describe 'has_required_fields?' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"filename"=>"snow-cap.jpg", "accession_number"=>"20181218/1", "reference"=>"U TEST", "title"=>"test"},
        {"filename"=>"README.txt", "accession_number"=>"", "reference"=>"U TEST", "title"=>"test2"}
      ]
    end
    it 'returns true if the required fields exist' do
      expect(@sc.send(:has_required_fields?, @rows[0], 1)).to eq true
    end
    it 'returns false if the required fields do not exist' do
      expect(@sc.send(:has_required_fields?, @rows[1], 2)).to eq false
      expect(@sc.errors).to eq (["Required fields error in spec/fixtures/files/submission/test1/DESCRIPTION.csv, row 2"])
    end
  end

  describe 'has_calm_collection?' do
    before do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      @rows = [
        {"filename"=>"snow-cap.jpg", "accession_number"=>"20181218/1", "reference"=>"U TEST", "title"=>"test"},
        {"filename"=>"README.txt", "accession_number"=>"", "reference"=>" ", "title"=>"test2"}
      ]
      allow(calm_api).to receive(:get_record_by_field).with('RefNo', 'U TEST').and_return([true, { 'RecordID' => ['12345'] }])
    end
    it 'returns false if the reference field does not exist' do
      expect(@sc.send(:has_calm_collection?, @rows[1], 2)).to eq false
      expect(@sc.errors).to eq (["CALM collection reference is missing in spec/fixtures/files/submission/test1/DESCRIPTION.csv, row 2"])
    end
    skip 'returns true if the reference is available in calm do' do
      # TODO: The calm_api isn't being mocked
      expect(@sc.send(:has_calm_collection?, @rows[0], 1)).to eq true
      expect(@sc.errors).to eq ([])
    end
  end

  describe 'add_checked_file' do
    before(:each) do
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission'} })
      @fn = "spec/fixtures/files/submission/test4"
      @files = [
        "#{@fn}",
        "#{@fn}/a0f43446-5488-4f54-840e-574692594504.jpg",
        "#{@fn}/ca77863e-dd5b-43bb-9f9d-abcbf40c1c02.jpg",
        "#{@fn}/docs",
        "#{@fn}/docs/METS.bff59767-3d3f-4032-914c-c7ebebf87aa7.xml",
        "#{@fn}/docs/processingMCP.xml",
        "#{@fn}/xml",
        "#{@fn}/xml/files.xlsx",
      ]
      @files_in_doc = [
        "#{@fn}/docs",
        "#{@fn}/docs/METS.bff59767-3d3f-4032-914c-c7ebebf87aa7.xml",
        "#{@fn}/docs/processingMCP.xml"
      ]
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
    end
    it 'returns all the checked files for a dir' do
      @sc.send(:add_checked_file, "spec/fixtures/files/submission/test4/docs")
      expect(@sc.instance_variable_get(:@checked_files_in_metadata)).to match_array(@files_in_doc)
    end
    it 'returns all the checked files for a dir including any subdirs' do
      @sc.send(:add_checked_file, "spec/fixtures/files/submission/test4")
      expect(@sc.instance_variable_get(:@checked_files_in_metadata)).to match_array(@files)
    end
    it 'does not add checked files for remote files' do
      @sc.send(:add_checked_file, "/data_dir/efs/test4/docs")
      expect(@sc.instance_variable_get(:@checked_files_in_metadata)).to eq([])
    end
  end

  describe 'has_unverified_files?' do
    before(:each) do
      @fn = "spec/fixtures/files/submission/test3"
      @sc = SubmissionChecker.new({ params: {source_dir: @fn} })
      @some_files = [
        "#{@fn}/a0f43446-5488-4f54-840e-574692594504.jpg",
        "#{@fn}/ca77863e-dd5b-43bb-9f9d-abcbf40c1c02.jpg",
        "#{@fn}/DESCRIPTION.csv",
        "#{@fn}/FILES.csv",
        "#{@fn}/metadata/files.xlsx",
        "#{@fn}/submissionDocumentation/METS.bff59767-3d3f-4032-914c-c7ebebf87aa7.xml",
        "#{@fn}/submissionDocumentation/processingMCP.xml"
      ]
      @other_files = [
        "#{@fn}/README.txt",
        "#{@fn}/snow-cap.jpg",
      ]
      @all_files = @some_files + @other_files
    end
    it 'all files are verified' do
      @sc.instance_variable_set(:@checked_files_in_file, @all_files)
      expect(@sc.send(:has_unverified_files?)).to eq false
      expect(@sc.errors).to eq ([])
    end
    it 'Some files are not verified' do
      @sc.instance_variable_set(:@checked_files_in_file, @some_files)
      expect(@sc.send(:has_unverified_files?)).to eq true
      error_message = [
        "There are files in the submission not listed in #{@fn}/FILES.csv and so not verified.",
        "  - #{@fn}/README.txt",
        "  - #{@fn}/snow-cap.jpg"
      ]
      expect(@sc.errors).to match_array error_message
    end
  end

  describe 'has_unused_files?' do
    before(:each) do
      @fn = "spec/fixtures/files/submission/test3"
      @sc = SubmissionChecker.new({ params: {source_dir: @fn} })
      @some_files = [
        "#{@fn}/a0f43446-5488-4f54-840e-574692594504.jpg",
        "#{@fn}/ca77863e-dd5b-43bb-9f9d-abcbf40c1c02.jpg",
        "#{@fn}/metadata/files.xlsx",
        "#{@fn}/submissionDocumentation/METS.bff59767-3d3f-4032-914c-c7ebebf87aa7.xml",
        "#{@fn}/submissionDocumentation/processingMCP.xml"
      ]
      @other_files = [
        "#{@fn}/README.txt",
        "#{@fn}/snow-cap.jpg",
      ]
      @all_files = @some_files + @other_files
    end
    it 'all files are used' do
      @sc.instance_variable_set(:@checked_files_in_metadata, @all_files)
      expect(@sc.send(:has_unused_files?)).to eq false
      expect(@sc.errors).to eq ([])
    end
    it 'some files are not used' do
      @sc.instance_variable_set(:@checked_files_in_metadata, @some_files)
      expect(@sc.send(:has_unused_files?)).to eq true
      error_message = [
        "There are files in the submission not listed in #{@fn}/DESCRIPTION.csv and so not used.",
        "  - #{@fn}/README.txt",
        "  - #{@fn}/snow-cap.jpg"
      ]
      expect(@sc.errors).to match_array error_message
    end
  end

  describe 'get_data_path' do
    before do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
    end
    it 'returns nil if filepath is nil' do
      expect(@sc.send(:get_data_path, ' ')).to be_nil
    end
    it 'returns sanitized path if filepath starts with remote dir' do
      expect(@sc.send(:get_data_path, '\data_dir\efs\test1 ')).to eq('/data_dir/efs/test1')
    end
    it 'returns sanitized path if filepath starts with source dir' do
      expect(@sc.send(:get_data_path, ' test\123/asdf ')).to eq('test/123/asdf')
    end
    it 'returns sanitized path with source dir prefixed for filepath' do
      expect(@sc.send(:get_data_path, ' test123/asdf ')).to eq('test/test123/asdf')
    end
  end

  describe 'is_remote_file?' do
    before do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test'} })
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
    end
    it 'returns false if filepath is nil' do
      expect(@sc.send(:is_remote_file?, ' ')).to eq false
    end
    it 'returns true if filepath starts with remote dir' do
      expect(@sc.send(:is_remote_file?, '\data_dir\efs\test1 ')).to eq true
    end
    it 'returns false if filepath starts with source dir' do
      expect(@sc.send(:is_remote_file?, ' data_dir\efs\test1')).to eq false
    end
  end

  describe 'is_local_file?' do
    before do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test123'} })
    end
    it 'returns false if filepath is nil' do
      expect(@sc.send(:is_local_file?, ' ')).to eq false
    end
    it 'returns true if filepath starts with source dir' do
      expect(@sc.send(:is_local_file?, 'test123\test1/test1a ')).to eq true
    end
    it 'returns false if filepath does not start with source dir' do
      expect(@sc.send(:is_local_file?, 'test1234/asdf')).to eq false
    end
  end

  describe 'sanitized_filepath' do
    before do
      @sc = SubmissionChecker.new({ params: {source_dir: 'test123'} })
    end
    it 'strips spaces from the beginning and end of filenames' do
      expect(@sc.send(:sanitized_filepath, 'test123/test1/test1a ')).to eq('test123/test1/test1a')
      expect(@sc.send(:sanitized_filepath, ' test123/test1/test1b')).to eq('test123/test1/test1b')
      expect(@sc.send(:sanitized_filepath, ' test123/test1/test1c ')).to eq('test123/test1/test1c')
    end
    it 'converts windows and unix files eparators to unix style' do
      expect(@sc.send(:sanitized_filepath, 'test123\test1/test1a\b')).to eq('test123/test1/test1a/b')
    end
    it 'removes the slash from the end of the filepath' do
      expect(@sc.send(:sanitized_filepath, 'test123\test1/test1a\b\\')).to eq('test123/test1/test1a/b')
    end
    it 'removes spaces, handles different file separators and removes the slash from the end of the filepath' do
      expect(@sc.send(:sanitized_filepath, '/test123\test1/test1a\b\ ')).to eq('/test123/test1/test1a/b')
    end
  end

  describe 'submitted_files' do
    it 'lists all files from the current directory and its sub directories' do
      fn = "spec/fixtures/files/submission/test3"
      files = [
        "#{fn}/a0f43446-5488-4f54-840e-574692594504.jpg",
        "#{fn}/ca77863e-dd5b-43bb-9f9d-abcbf40c1c02.jpg",
        "#{fn}/DESCRIPTION.csv",
        "#{fn}/FILES.csv",
        "#{fn}/README.txt",
        "#{fn}/snow-cap.jpg",
        "#{fn}/metadata/files.xlsx",
        "#{fn}/submissionDocumentation/METS.bff59767-3d3f-4032-914c-c7ebebf87aa7.xml",
        "#{fn}/submissionDocumentation/processingMCP.xml"
      ]
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test3/'} })
      expect(@sc.send(:submitted_files)).to match_array(files)
    end

  describe 'submitted_data_files' do
    it 'lists all data files from the current directory and its sub directories' do
      fn = "spec/fixtures/files/submission/test3"
      files = [
        "#{fn}/a0f43446-5488-4f54-840e-574692594504.jpg",
        "#{fn}/ca77863e-dd5b-43bb-9f9d-abcbf40c1c02.jpg",
        "#{fn}/README.txt",
        "#{fn}/snow-cap.jpg",
      ]
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test3/'} })
      expect(@sc.send(:submitted_data_files)).to match_array(files)
    end
  end

  describe 'get_hash' do
    it 'gets the md5 checksum for a file' do
      md5_sum = '93d7c1702e662083ae3083f452b7a472'
      @sc = SubmissionChecker.new({ params: {source_dir: 'spec/fixtures/files/submission/test1/'} })
      expect(@sc.send(:get_hash, 'spec/fixtures/files/submission/test1/snow-cap.jpg')).to eq(md5_sum)
    end
  end

  end

end





