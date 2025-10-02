require "json"

require "trove"

module Wool
  alias Id = Trove::Oid
end

module Trove
  struct Oid
    def to_json(json : JSON::Builder)
      json.string string
    end

    def to_yaml(yaml : YAML::Nodes::Builder)
      yaml.scalar @value
    end

    def initialize(pull : JSON::PullParser)
      @value = (Oid.from_string pull.read_string).value
    end

    def initialize(pull : YAML::PullParser)
      @value = (Oid.from_string pull.read_scalar).value
    end

    def self.from_serializable(s)
      j = s.to_json
      r = LibXxhash.xxhash128 j.to_slice, j.bytesize, 0
      Oid.new({r.high64, r.low64})
    end
  end
end
