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

  enum Type : UInt8
    AnswerTo        = 0
    NegationOf      = 1
    VersionOf       = 2
    ClarificationOf = 3
    ConsequenceOf   = 4
    PartOf          = 5
  end

  alias Relation = {from: Id, to: Id, type: Type}
  alias Content = String | Relation
  alias Thesis = {content: Content, relations: {from: Set(Id), to: Set(Id)}, tags: Set(String)}

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

    def get(id : Id) : Thesis?
      {content:   (Content.from_json (chest.get id.to_oid).not_nil!["content"].to_json rescue return nil),
       relations: {from: (Set.new (chest.where "content.from", id.to_string).map { |oid| Id.from_oid oid }),
                   to: (Set.new (chest.where "content.to", id.to_string).map { |oid| Id.from_oid oid })},
       tags: Set.new index.get id.to_bytes}
    end

    def delete(id : Id)
      chest.transaction do |tx|
        d = (chest.where "content.from", id.to_string) + (chest.where "content.to", id.to_string)
        d.each { |oid| tx.delete oid }
        d.each { |oid| index.delete (Id.from_oid oid).to_bytes }
      end
    end

    def get(present : Array(String), absent : Array(String) = [] of String, limit : UInt32 = UInt32::MAX, from : Id? = nil)
      (index.find present, absent, limit, (from ? from.to_bytes : nil)).map { |b| Id.from_bytes b }
    end
  end
end
