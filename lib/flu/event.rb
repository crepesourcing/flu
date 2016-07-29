module Flu
  class Event

    def initialize(emitter, kind, name, data)
      @meta = {
        id:        SecureRandom.uuid,
        name:      name,
        emitter:   emitter,
        timestamp: Time.now.utc,
        kind:      kind,
        replayed:  false
      }
      @data = data
    end

    def to_routing_key
      "#{@meta[:emitter]}.#{@meta[:kind]}.#{@meta[:name]}"
    end

    def to_json(options=nil)
      {
        meta: @meta,
        data: map_complex_object(@data)
      }.to_json(options)
    end

    def id
      @meta[:id]
    end

    def timestamp=(new_timestamp)
      @meta[:timestamp] = new_timestamp
    end

    def mark_as_replayed
      @meta[:replayed] = true
    end

    private

    def map_complex_object(object)
      if object.is_a?(Array)
        map_array(object)
      elsif object.is_a?(Hash)
        map_hash(object)
      elsif object.is_a?(ActionDispatch::Http::UploadedFile)
        map_file(object)
      else
        object
      end
    end

    def map_array(object)
      array = []
      object.each do |value|
        array.push(map_complex_object(value))
      end
      array
    end

    def map_hash(object)
      hash = {}
      object.each do |key, value|
        hash[key] = map_complex_object(value)
      end
      hash
    end

    def map_file(object)
      {
        "file_name":    object.original_filename,
        "content_type": object.content_type
      }
    end

  end
end

