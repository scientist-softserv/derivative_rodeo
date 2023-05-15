# frozen_string_literal: true

require 'derivative_rodeo/storage_targets/concerns/download_concern'

module DerivativeRodeo
  module StorageTargets
    ##
    # Target for files from the web. Download only, can not write!
    class HttpsTarget < BaseTarget
      include DownloadConcern
    end
  end
end
