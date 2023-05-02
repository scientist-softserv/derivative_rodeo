# frozen_string_literal: true

RSpec.describe DerivativeRedeo::StorageAdapter::FileAdapter do
  let(:file_path) { File.expand_path(File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff')) }
  let(:new_path) { File.expand_path(File.join(FIXTURE_PATH, 'tmp', 'ocr_color.tiff')) }
  let(:short_path) { file_path.split('/')[-2..-1].join('/') }
  let(:args) { "file://#{file_path}" }

  subject { described_class.new(args) }

  it "creates a properly formatted uri from a file path with all parts as default" do
    expect(described_class.create_uri(path: file_path)).to eq(args)
  end

  it "creates a properly formatted uri from a file path with all parts" do
    expect(described_class.create_uri(path: file_path, parts: :all)).to eq(args)
  end

  it "creates a properly formatted uri from a file path with 2 path parts" do
    expect(described_class.create_uri(path: file_path, parts: 2)).to eq("file://#{short_path}")
  end

  xit "throws an exception if path is malformed" do
    expect(described_class.create_uri(path: file_path)).to eq('s3://fake-bucket.s3.us-east-1.amazonaws.com/files/ocr_color.tiff')
  end

  it "creates a tmp path, downloads the file, and deletes the tmp path at the end" do
    @tmp_path = nil
    subject.with_existing_tmp_path do |tmp_path|
      @tmp_path = tmp_path
      expect(File.exist?(@tmp_path)).to be true
    end
    expect(File.exist?(@tmp_path)).to be false
  end

  xit "write additional with_tmp_path cases"

  context "writes to the tmp directory" do
    let(:args) { "file://#{new_path}" }

    before do
      FileUtils.rm_f(new_path)
    end

    it "writes a file to the bucket" do
      @tmp_path = nil
      subject.with_new_tmp_path do |tmp_path|
        @tmp_path = tmp_path
        # copy a file in so we can test that its uploaded
        FileUtils.cp(file_path, @tmp_path)
        subject.write
        expect(File.exist?(@tmp_path)).to be true
      end
      expect(File.exist?(new_path)).to be true
      expect(File.exist?(@tmp_path)).to be false
    end

    xit "write additional write cases"

    after do
      FileUtils.rm_f(new_path)
    end
  end
  xit "write cases or mark private the rest of the methods"
end
