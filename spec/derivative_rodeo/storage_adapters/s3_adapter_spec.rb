# frozen_string_literal: true

RSpec.describe DerivativeRodeo::StorageAdapters::S3Adapter do
  let(:file_path) { File.expand_path(File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff')) }
  let(:short_path) { file_path.split('/')[-2..-1].join('/') }
  let(:args) { "s3://fake-bucket.s3.eu-west-1.amazonaws.com/#{short_path}" }
  let(:bucket) do
    bucket = AwsS3FauxBucket.new
    bucket.object(short_path).upload_file(file_path)
    bucket
  end

  subject { described_class.new(args) }

  before do
    DerivativeRodeo.config do |config|
      config.aws_s3_bucket = 'fake-bucket'
      config.aws_s3_access_key_id = "FAKEFAKEFAKE"
      config.aws_s3_secret_access_key = "FAKEFAKEFAKEFAKER"
    end
  end

  it "creates a properly formatted uri from a file path with 2 path parts as default" do
    expect(described_class.create_uri(path: file_path)).to eq("s3://fake-bucket.s3.us-east-1.amazonaws.com/files/ocr_color.tiff")
  end

  it "creates a properly formatted uri from a file path with all parts" do
    expect(described_class.create_uri(path: file_path, parts: :all)).to eq("s3://fake-bucket.s3.us-east-1.amazonaws.com/#{file_path}")
  end

  it "creates a properly formatted uri from a file path with 4 path parts" do
    expect(described_class.create_uri(path: file_path, parts: 4)).to eq("s3://fake-bucket.s3.us-east-1.amazonaws.com/spec/fixtures/files/ocr_color.tiff")
  end

  xit "throws an exception if path is malformed" do
    expect(described_class.create_uri(path: file_path)).to eq('s3://fake-bucket.s3.us-east-1.amazonaws.com/files/ocr_color.tiff')
  end

  it "creates a tmp path, downloads the file, and deletes the tmp path at the end" do
    @tmp_path = nil
    file = subject
    file.bucket = bucket
    file.with_existing_tmp_path do |tmp_path|
      @tmp_path = tmp_path
      expect(File.exist?(@tmp_path)).to be true
    end
    expect(File.exist?(@tmp_path)).to be false
  end

  xit "write additional with_tmp_path cases"

  it "writes a file to the bucket" do
    @tmp_path = nil
    file = subject
    file.bucket = bucket
    file.with_new_tmp_path(auto_write_file: false) do |tmp_path|
      @tmp_path = tmp_path
      # copy a file in so we can test that its uploaded
      FileUtils.cp(file_path, @tmp_path)
      file.write
      expect(File.exist?(@tmp_path)).to be true
    end
    expect(bucket.object(short_path)).to be
    expect(File.exist?(@tmp_path)).to be false
  end

  xit "write additional write cases"
  xit "write cases or mark private the rest of the methods"
end
