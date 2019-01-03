require 'csv'
require 'fileutils'
require 'submission_processor'
RSpec.describe SubmissionProcessor do

  describe 'Initialize with source dir' do
    it 'needs params' do
      expect{ SubmissionProcessor.new() }.to raise_error(ArgumentError, 'missing keyword: params')
    end
    it 'raises error if no source_dir' do
      expect{ SubmissionProcessor.new({ params: {source_dir: ''} }) }.to raise_error(RuntimeError, 'Source directory not provided')
    end
    it 'initializes with source dir' do
      expect{ SubmissionProcessor.new({ params: {source_dir: 'test'} }) }.not_to raise_error
    end
  end

  describe 'it sets read attributes' do
    before do
      @sp = SubmissionProcessor.new({ params: {source_dir: 'test'} })
    end
    it 'has status' do
      expect(@sp.params).to eq ({source_dir: 'test'})
      expect(@sp.source_dir).to eq('test/')
      expect(@sp.current_transfer_dir).to be_nil
      expect(@sp.accession).to be_nil
    end
  end

  describe 'process_submission' do
    before do
      @sp = SubmissionProcessor.new({ params: {source_dir: 'test'} })
    end
    it 'processes the submission' do
      allow(@sp).to receive(:assemble_data).and_return(true)
      allow(@sp).to receive(:assemble_archival_files).and_return(true)
      allow(@sp).to receive(:build_bag).and_return(true)
      allow(@sp).to receive(:cleanup).with('test/', check_empty: false).and_return(true)
      expect(@sp.process_submission).to eq(true)
    end
  end

  describe 'assemble_data' do
    before do
      fn = 'spec/fixtures/files/submission/test1/DESCRIPTION.csv'
      @source = 'spec/fixtures/files/submission/test1'
      @sp = SubmissionProcessor.new({ params: {source_dir: @source} })
      @csv_rows = []
      ::CSV.foreach(fn, headers: true).each do |csv_row|
        @csv_rows.append(csv_row)
      end
      @rows = [
        {"filename"=>"snow-cap.jpg", "accession_number"=>"20181218/1", "reference"=>"U TEST"},
        {"filename"=>"README.txt", "accession_number"=>"20181218/2", "reference"=>"U TEST"}
      ]
    end
    it 'assemble the data with local and remote files and directories' do
      # local file
      allow(@sp).to receive(:create_data_dir).with('work1').and_return("#{@source}/__processed_data/work1")
      allow(@sp).to receive(:is_remote_file?).with("snow-cap.jpg").and_return(false)
      allow(@sp).to receive(:is_remote_file?).with("#{@source}/snow-cap.jpg").and_return(false)
      allow(FileUtils).to receive(:mv).with("#{@source}/snow-cap.jpg", "#{@source}/__processed_data/work1").and_return(true)
      allow(@sp).to receive(:write_metadata).with(@rows[0], "#{@source}/__processed_data/work1").and_return(true)
      # local file
      allow(@sp).to receive(:create_data_dir).with('work2').and_return("#{@source}/__processed_data/work2")
      allow(@sp).to receive(:is_remote_file?).with("README.txt").and_return(false)
      allow(@sp).to receive(:is_remote_file?).with("#{@source}/README.txt").and_return(false)
      allow(FileUtils).to receive(:mv).with("#{@source}/README.txt", "#{@source}/__processed_data/work2").and_return(true)
      allow(@sp).to receive(:write_metadata).with(@rows[1], "#{@source}/__processed_data/work2").and_return(true)
      # TODO: local directory
      # TODO: remote file
      # TODO: remote directory
      expect(@sp.send(:assemble_data)).to eq(nil)
    end
  end

  describe 'assemble_archival_files' do
    before do
      @sp = SubmissionProcessor.new({ params: {source_dir: 'test'} })
    end
    it 'assembles the archival data' do
      package_dir = 'test/__processed_data/package'
      allow(@sp).to receive(:move_files_file).with(package_dir).and_return(true)
      allow(@sp).to receive(:move_metadata_file).with(package_dir).and_return(true)
      allow(@sp).to receive(:move_submission_doc).with(package_dir).and_return(true)
      allow(@sp).to receive(:move_metadata_dir).with(package_dir).and_return(true)
      allow(@sp).to receive(:move_extra_files).with(package_dir).and_return(true)
      expect(@sp.send(:assemble_archival_files)).to eq(true)
    end
  end

  describe 'build_bag' do
    # TODO
    skip 'for now'
  end

  describe 'has_extra_files?' do
    before do
      @sp = SubmissionProcessor.new({ params: {source_dir: 'test'} })
    end
    it 'returns true if it has extra files' do
      allow(@sp).to receive(:extra_files).and_return(['one', 'two'])
      expect(@sp.send(:has_extra_files?)).to eq(true)
    end
    it 'returns false if it does not have extra files' do
      allow(@sp).to receive(:extra_files).and_return([])
      expect(@sp.send(:has_extra_files?)).to eq(false)
    end
  end

  describe 'get_dirname' do
    before do
      @sp = SubmissionProcessor.new({ params: {source_dir: '/test'} })
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs')
    end
    it 'returns the file name for a local file' do
      fn = 'abcd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_dirname, fn, 1)).to eq('work1')
    end
    it 'returns the directory and file name for a local file in a directory' do
      fn = '/test/abcd/defg/acd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_dirname, fn, 2)).to eq('work2__abcd__defg')
    end
    it 'returns the directory name for a local directory' do
      fn = '/test/abcd/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_dirname, fn, 3)).to eq('work3__abcd')
    end
    it 'returns the directory name for a local directory in a directory' do
      fn = '/test/abcd/efgh/ijkl/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_dirname, fn, 4)).to eq('work4__abcd__efgh__ijkl')
    end
    it 'returns the file name for a remote file' do
      fn = '/data_dir/efs/abcd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_dirname, fn, 5)).to eq('work5')
    end
    it 'returns the directory and file name for a remote file in a directory' do
      fn = '/data_dir/efs/abcd/defg/acd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_dirname, fn, 6)).to eq('work6__abcd__defg')
    end
    it 'returns the directory name for a remote directory' do
      fn = '/data_dir/efs/abcd/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_dirname, fn, 7)).to eq('work7__abcd')
    end
    it 'returns the directory name for a remote directory in a directory' do
      fn = '/data_dir/efs/abcd/efgh/ijkl/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_dirname, fn, 8)).to eq('work8__abcd__efgh__ijkl')
    end
  end

  describe 'get_relative_path' do
    before do
      @sp = SubmissionProcessor.new({ params: {source_dir: '/test'} })
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs/')
    end
    it 'returns the relative path for a local file' do
      fn = 'abcd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd.txt')
    end
    it 'returns the relative path for a local file in a directory' do
      fn = '/test/abcd/defg/acd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd/defg/acd.txt')
    end
    it 'returns the relative path for a local directory' do
      fn = '/test/abcd/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd')
    end
    it 'returns the relative path for a local directory in a directory' do
      fn = '/test/abcd/efgh/ijkl/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd/efgh/ijkl')
    end
    it 'returns the relative path for a remote file' do
      fn = '/data_dir/efs/abcd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd.txt')
    end
    it 'returns the relative path for a remote file in a directory' do
      fn = '/data_dir/efs/abcd/defg/acd.txt'
      allow(File).to receive(:file?).with(fn).and_return(true)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd/defg/acd.txt')
    end
    it 'returns the relative path for a remote directory' do
      fn = '/data_dir/efs/abcd/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd')
    end
    it 'returns the relative path for a remote directory in a directory' do
      fn = '/data_dir/efs/abcd/efgh/ijkl/'
      allow(File).to receive(:file?).with(fn).and_return(false)
      expect(@sp.send(:get_relative_path, fn)).to eq('abcd/efgh/ijkl')
    end
  end

  describe 'create_data_dir' do
    before do
      @sp = SubmissionProcessor.new({ params: {source_dir: 'test'} })
      allow(ENV).to receive(:[]).with('LOCAL_EFS_DATA_DIR').and_return('/data_dir/efs/')
    end
    it 'creates a directory with a relative_path' do
      dirnames = %w(work1 work4__abcd__efgh__ijkl work7__abcd)
      dirnames.each do |dn|
        allow(FileUtils).to receive(:mkdir_p).with("test/__processed_data/#{dn}").and_return(true)
        expect(@sp.send(:create_data_dir, dn)).to eq("test/__processed_data/#{dn}")
      end
    end
  end

  describe 'write_metadata' do
    # fn = 'spec/fixtures/files/submission/test1/DESCRIPTION.csv'
    # dest_dir = 'tmp/test1'
    # testIO = StringIO.new
    # # allow(File).to receive(:open).with('tmp/test1/metadata.json').and_return(testIO)
  end

end
