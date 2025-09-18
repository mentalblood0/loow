require "json"

module Wool
  struct Id
    @value : String

    protected def initialize(@value)
    end

    def <=>(other : Id)
      to_string <=> other.to_string
    end

    def to_json(json : JSON::Builder)
      json.string @value
    end

    def to_bytes
      @value.hexbytes
    end

    def to_oid : Trove::Oid
      b = to_bytes
      {IO::ByteFormat::BigEndian.decode(UInt64, b[0..7]),
       IO::ByteFormat::BigEndian.decode(UInt64, b[8..15])}
    end

    def to_string : String
      @value
    end

    def initialize(pull : JSON::PullParser)
      @value = pull.read_string
    end

    def self.from_oid(oid : Trove::Oid)
      r = Bytes.new 16
      IO::ByteFormat::BigEndian.encode oid[0], r[0..7]
      IO::ByteFormat::BigEndian.encode oid[1], r[8..15]
      new r.hexstring
    end

    def self.from_bytes(b : Bytes)
      new b.hexstring
    end

    def self.from_string(s : String)
      new s
    end

    def self.from_content(c : String)
      r = LibXxhash.xxhash128 c.to_slice, c.bytesize, 0
      from_oid({r.high64, r.low64})
    end

    def self.from_content(rel : Relation)
      t = rel[:type]
      src = rel[:from].to_bytes + rel[:to].to_bytes + pointerof(t).as(UInt8*).to_slice(1)
      r = LibXxhash.xxhash128 src.to_slice, src.bytesize, 0
      from_oid({r.high64, r.low64})
    end
  end
end
