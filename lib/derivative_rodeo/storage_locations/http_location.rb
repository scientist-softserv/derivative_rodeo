# frozen_string_literal: true

require 'derivative_rodeo/storage_locations/concerns/download_concern'

module DerivativeRodeo
  module StorageLocations
    ##
    # Location for files from the web. Download only, can not write!
    class HttpLocation < BaseLocation
      include DownloadConcern
    end
  end
end
