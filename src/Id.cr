require "json"

require "trove"

module Wool
  alias Id = Trove::Oid
end

module Trove
  struct Oid
    def to_json(json : JSON::Builder)
      json.string to_string
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

    def self.from_content(c : String)
      r = LibXxhash.xxhash128 c.to_slice, c.bytesize, 0
      Oid.new({r.high64, r.low64})
    end

    def self.from_content(rel : Wool::Relation)
      t = rel[:type]
      src = rel[:from].to_bytes + rel[:to].to_bytes + pointerof(t).as(UInt8*).to_slice(1)
      r = LibXxhash.xxhash128 src.to_slice, src.bytesize, 0
      Oid.new({r.high64, r.low64})
    end

    def self.from_ids(i1 : Oid, i2 : Oid)
      r = Bytes.new 16
      i1b = i1.to_bytes
      i2b = i2.to_bytes
      16.times do |i|
        r[i] = i1b[i] ^ i2b[i]
      end
      Oid.from_bytes r
    end
  end
end
