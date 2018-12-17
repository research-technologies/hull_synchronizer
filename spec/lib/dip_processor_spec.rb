require 'dip_processor'

RSpec.describe DIPProcessor do
  let(:processor) { described_class }
  let(:reader) { DIPReader }
  let(:reader_instance) { instance_double(DIPReader) }
  let(:processor_instance) { processor.new(params: params) }

  describe 'dip_processor' do
    context 'without required params' do
      it 'raises a missing required params error' do
        expect { processor.new(params: {}) }.to raise_error(RuntimeError, 'Missing required params: [:dip_location] and [:package_metadata][:dip_uuid] are required')
      end
    end

    context 'with required params, but incorrect dip_location' do
      let(:params) { { dip_location: 'some_incorrect_path', package_metadata: { dip_uuid: 'dip_uuid' } } }
      it 'receives an error from DIPReader' do
        expect { processor.new(params: params) }.to raise_error(RuntimeError, 'Cannot find DIP folder: some_incorrect_path')
      end
    end

    context 'with required params' do
      let(:params) { { dip_location: 'some_path', package_metadata: { dip_uuid: 'dip_uuid' } } }

      before do
        allow(reader).to receive(:new).with(params[:dip_location]).and_return(reader_instance)
      end

      it 'sets the correct attributes' do
        expect(processor_instance.dip_id).to eq('dip_uuid')
        expect(processor_instance.bag_key).to eq('dip_uuid')
        expect(processor_instance.dip).to eq(reader_instance)
      end
    end

    context '#process' do
      ENV['BAGS_DIR'] = 'spec/fixtures/files/dip/tmp'
      let(:params) { { dip_location: 'spec/fixtures/files/dip/2018-12-18T14-53-11-983442237-bff59767-3d3f-4032-914c-c7ebebf87aa7', package_metadata: { dip_uuid: 'b219c7dd-39a2-4d72-89a6-50cf3309e7a0' } } }

      it 'creates the zipped bags for the package and work' do
        processor_instance.process
        expect(File.exist?('spec/fixtures/files/dip/tmp/b219c7dd-39a2-4d72-89a6-50cf3309e7a0.zip')).to be_truthy
        expect(File.exist?('spec/fixtures/files/dip/tmp/b219c7dd-39a2-4d72-89a6-50cf3309e7a0_work1.zip')).to be_truthy
      end

      after do
        FileUtils.rm(File.join(Rails.root, 'spec/fixtures/files/dip/tmp/b219c7dd-39a2-4d72-89a6-50cf3309e7a0.zip'))
        FileUtils.rm(File.join(Rails.root, 'spec/fixtures/files/dip/tmp/b219c7dd-39a2-4d72-89a6-50cf3309e7a0_work1.zip'))
      end
    end
  end
end
