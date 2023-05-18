# frozen_string_literal: true

RSpec.describe DerivativeRodeo::StorageTargets::SqsTarget do
  let(:file_path) { File.expand_path(File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff')) }
  let(:short_path) { file_path.split('/')[-2..-1].join('/') }
  let(:args) { "sqs://eu-west-1.amazonaws.com/55555555/fake-queue/#{short_path}?template=s3://adventist-preprocess.s3.us-west-1.amazonaws.com/preprocess/{{dir_parts[-1..-1]}}/{{ filename }}" }
  let(:client) { AwsSqsFauxClient.new }

  subject { described_class.new(args) }

  before do
    DerivativeRodeo.config do |config|
      config.aws_sqs_queue = 'fake-queue'
      config.aws_sqs_account_id = '55555555'
      config.aws_sqs_access_key_id = "FAKEFAKEFAKE"
      config.aws_sqs_secret_access_key = "FAKEFAKEFAKEFAKER"
    end
  end

  it "creates a properly formatted uri from a file path with 2 path parts as default" do
    expect(described_class.create_uri(path: file_path)).to eq("sqs://us-east-1.amazonaws.com/55555555/fake-queue/ocr_color.tiff")
  end

  it "creates a properly formatted uri from a file path with all parts" do
    expect(described_class.create_uri(path: file_path, parts: :all)).to eq("sqs://us-east-1.amazonaws.com/55555555/fake-queue/#{file_path}")
  end

  it "creates a properly formatted uri from a file path with 4 path parts" do
    expect(described_class.create_uri(path: file_path, parts: 4)).to eq("sqs://us-east-1.amazonaws.com/55555555/fake-queue/spec/fixtures/files/ocr_color.tiff")
  end

  xit "throws an exception if path is malformed" do
    expect(described_class.create_uri(path: file_path)).to eq('sqs://us-east-1.amazonaws.com/55555555/fake-queue/files/ocr_color.tiff')
  end

  it "writes a file path to the queue" do
    @tmp_path = nil
    file = subject
    file.client = client
    file.with_new_tmp_path(auto_write_file: false) do |tmp_path|
      @tmp_path = tmp_path
      # copy a file in so we can test that its uploaded
      FileUtils.cp(file_path, @tmp_path)
      file.write
      expect(File.exist?(@tmp_path)).to be true
    end
    # {"https://sqs.us-west-2.amazonaws.com/5555555555/fake"=>[{:id=>"0", :message_body=>"/var/folders/43/3hsph86d56b4mzpzhrbq2fm00000gn/T/d20230510-36732-1civ6nm/ocr_color.tiff"}]}
    expect(client.storage).to be
    expect(client.storage["https://sqs.us-west-2.amazonaws.com/5555555555/fake"].size).to eq(1)

    result_body = client.storage["https://sqs.us-west-2.amazonaws.com/5555555555/fake"].first[:message_body]
    result_json = JSON.parse(result_body)
    expect(result_json.keys.first).to eq('s3://adventist-preprocess.s3.us-west-1.amazonaws.com/preprocess/files/ocr_color.tiff')
    expect(result_json.values.first).to eq(['s3://adventist-preprocess.s3.us-west-1.amazonaws.com/preprocess/{{dir_parts[-1..-1]}}/{{ filename }}'])
    expect(File.exist?(@tmp_path)).to be false
  end

  xit "write additional write cases"
  xit "write cases or mark private the rest of the methods"
end
