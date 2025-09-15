require "yaml"

require "trove"
require "dream"
require "xxhash128"

module Wool
  class Exception < Exception
  end

  struct Id
    @value : String

    protected def initialize(@value)
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
      oid0 = oid[0]
      oid1 = oid[1]
      new (pointerof(oid0).as(UInt8*).to_slice(8) + pointerof(oid1).as(UInt8*).to_slice(8)).hexstring
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

  enum Type : UInt8
    AnswerTo        = 0
    NegationOf      = 1
    VersionOf       = 2
    ClarificationOf = 3
    CosequenceOf    = 4
    PartOf          = 5
  end

  alias Relation = NamedTuple(from: Id, to: Id, type: Type)
  alias Content = String | Relation
  alias Thesis = NamedTuple(tags: Array(String)?, content: Content)

  class Sweater
    include YAML::Serializable
    include YAML::Serializable::Strict

    getter chest : Trove::Chest
    getter index : Dream::Index

    def add(c : Content)
      if c.is_a? Relation
        raise Exception.new "No \"from\" id #{c[:from].to_string} for relation" unless chest.has_key? c[:from].to_oid
        raise Exception.new "No \"to\" id #{c[:to].to_string} for relation" unless chest.has_key? c[:to].to_oid
      end

      id = Id.from_content c
      chest.set id.to_oid, "", JSON.parse({content: c}.to_json)
      id
    end

    def add(id : Id, tags : Array(String))
      index.add id.to_bytes, tags
    end

    def get(id : Id)
      Thesis.from_json (chest.get id.to_oid).to_json
    end
  end
end
