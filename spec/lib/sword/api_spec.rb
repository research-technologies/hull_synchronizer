RSpec.describe Sword::Api do
  ENV['SWORD_ENDPOINT'] = 'http://test.host'

  describe '#service_document' do
    let(:service_document) { described_class::ServiceDocument.new }
    let(:service_response) { file_fixture("service_document.xml").read }

    before do
      stub_request(:get, 'http://test.host/sword/service_document')
        .to_return(status: 200, body: service_response)
    end

    context 'returns and reads the service document' do
      before do
        service_document.request
      end

      it 'makes the call' do
        expect(service_document.request.status).to eq(200)
        expect(service_document.request.body).to eq(service_response)
      end

      it 'returns the collection url' do
        expect(service_document.collections).to eq(['http://test.host/sword/collections/default'])
      end
    end

    context 'with a http error' do
      before do
        stub_request(:get, 'http://test.host/sword/service_document')
          .to_return(status: 500)
        service_document.request
      end

      it 'returns no collections' do
        expect(service_document.collections).to eq([])
      end
    end
  end

  describe '#collection' do
    let(:collection) { described_class::Collection.new }
    let(:collection_response) { file_fixture("collection.xml").read }

    before do
      stub_request(:get, 'http://test.host/sword/collections/default')
        .to_return(status: 200, body: collection_response)
    end

    context 'returns and reads the collection' do
      before do
        collection.request
      end

      it 'makes the call' do
        expect(collection.request.status).to eq(200)
        expect(collection.request.body).to eq(collection_response)
      end

      it 'returns the deposit_urls' do
        expect(collection.works).to eq(['http://test.host/sword/collections/default/works'])
        expect(collection.file_sets).to eq(["http://test.host/sword/collections/default/works/hh63sv88v/file_sets"])
      end

      it 'returns the content' do
        expect(collection.content).to eq(['http://test.host/sword/collections/default/works/hh63sv88v'])
      end
    end

    context 'with a http error' do
      before do
        stub_request(:get, 'http://test.host/sword/collections/default')
          .to_return(status: 500)
        collection.request
      end

      it 'returns no deposit_urls' do
        expect(collection.works).to eq([])
        expect(collection.file_sets).to eq([])
        expect(collection.content).to eq([])
      end
    end
  end

  describe '#work' do
    let(:work) { described_class::Work.new(params: { file: { path: 'spec/fixtures/files/test_deposit.xml', content_type: 'application/xml' } }) }
    let(:work_response) { file_fixture("work.xml").read }

    before do
      stub_request(:post, 'http://test.host/sword/collections/default/works')
        .to_return(status: 201, body: work_response)
    end

    context 'deposits the work' do
      before do
        work.request
      end

      it 'makes the call' do
        expect(work.request.status).to eq(201)
        expect(work.request.body).to eq(work_response)
      end

      it 'returns the content and deposit_urls' do
        expect(work.deposit).to eq(content: "http://test.host/sword/collections/default/works/hh63sv88v", file_sets: ["http://test.host/sword/collections/default/works/hh63sv88v/file_sets"])
      end
    end
  end
end
