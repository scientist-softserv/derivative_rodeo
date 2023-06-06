# frozen_string_literal: true

RSpec.describe DerivativeRodeo::StorageLocations::S3Location do
  let(:file_path) { File.expand_path(File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff')) }
  let(:short_path) { file_path.split('/')[-2..-1].join('/') }
  let(:args) { "s3://fake-bucket.s3.eu-west-1.amazonaws.com/#{short_path}" }

  subject(:instance) { described_class.new(args) }

  before do
    # Let's use a FakeBucket instead!
    instance.use_actual_s3_bucket = false

    DerivativeRodeo.config do |config|
      config.aws_s3_bucket = 'fake-bucket'
      config.aws_s3_access_key_id = "FAKEFAKEFAKE"
      config.aws_s3_secret_access_key = "FAKEFAKEFAKEFAKER"
    end
  end

  context '.adapter_prefix' do
    context 'when no bucket is given' do
      subject { described_class.adapter_prefix }

      it 'uses the default config.aws_s3_bucket' do
        expect(subject).to eq("s3://fake-bucket.s3.us-east-1.amazonaws.com")
      end
    end

    context 'when given a bucket' do
      subject { described_class.adapter_prefix(bucket_name: "wonky-tonky") }

      it 'uses the given bucket_name' do
        expect(subject).to eq("s3://wonky-tonky.s3.us-east-1.amazonaws.com")
      end
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
    file.bucket.object(short_path).upload_file(file_path)

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
    file.with_new_tmp_path(auto_write_file: false) do |tmp_path|
      @tmp_path = tmp_path
      # copy a file in so we can test that its uploaded
      FileUtils.cp(file_path, @tmp_path)
      file.write
      expect(File.exist?(@tmp_path)).to be true
    end
    expect(subject.bucket.object(short_path)).to be
    expect(File.exist?(@tmp_path)).to be false
  end

  xit "write additional write cases"
  xit "write cases or mark private the rest of the methods"

  describe '#matching_locations_in_file_dir' do
    it 'searched the bucket' do
      # Because we instantiated the subject as a location to the :file_path (e.g. let(:file_path))
      # we are encoding where things are relative to this file.  In other words, this logic is
      # mirroring the generator logic that says where we're writing derivatives relative to their
      # original file/input file.
      bucket_dir = "files"

      original_basename_no_ext = File.basename(file_path, '.tiff')
      key = File.join(bucket_dir, "#{original_basename_no_ext}--page-1.tiff")
      subject.bucket.object(key).upload_file(__FILE__)

      non_matching_key = File.join(bucket_dir, "#{original_basename_no_ext}-skip--page-1.tiff")
      subject.bucket.object(non_matching_key).upload_file(__FILE__)

      locations = subject.matching_locations_in_file_dir(tail_regexp: %r{#{original_basename_no_ext}--page-\d+\.tiff$})

      expect(locations.size).to eq(1)
    end
  end
end
