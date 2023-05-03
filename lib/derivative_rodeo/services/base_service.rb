# frozen_string_literal: true

module DerivativeRodeo
  module Services
    ##
    # @api private
    #
    class BaseService
    end
  end
end

Dir.glob(File.join(__dir__, '**/*')).sort.each do |file|
  require file unless File.directory?(file) || file.match?(/base_service/)
end
