require "ostruct"

module Flu
  module ActionController
    class Base
    end
  end

  module ActionDispatch
    module Http
      class UploadedFile < OpenStruct
      end
    end
  end
end
