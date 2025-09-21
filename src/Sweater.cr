require "yaml"

require "trove"
require "dream"
require "xxhash128"

require "./Id"

module Wool
  class Exception < Exception
  end

  alias Relation = {from: Id, to: Id, type: String}
  alias Content = String | Relation
  alias Thesis = {content: Content, relations: {from: Set(Id), to: Set(Id)}, tags: Set(String)}

  class Sweater
    include YAML::Serializable
    include YAML::Serializable::Strict

    getter relations_types : Set(String)
    getter chest : Trove::Chest
    getter index : Dream::Index

    def add(c : Content)
      if c.is_a? Relation
        raise Exception.new "Relation type \"#{c[:type]}\" is not allowed in this Sweater" unless @relations_types.includes? c[:type]
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

    def delete(id : Id, tags : Array(String))
      index.delete id.to_bytes, tags
    end

    def get(id : Id) : Thesis?
      {content:   (Content.from_json (chest.get id.to_oid).not_nil!["content"].to_json rescue return nil),
       relations: {from: (Set.new (chest.where "content.from", id.to_string).map { |oid| Id.from_oid oid }),
                   to: (Set.new (chest.where "content.to", id.to_string).map { |oid| Id.from_oid oid })},
       tags: Set.new index.get id.to_bytes}
    end

    def get(c : String) : Thesis?
      get Id.from_oid (chest.unique "content", c).not_nil!
    end

    def delete(id : Id)
      chest.transaction do |ctx|
        index.transaction do |itx|
          ["content.from", "content.to"].each do |p|
            chest.where p, id.to_string do |oid|
              ctx.delete oid
              itx.delete (Id.from_oid oid).to_bytes
            end
          end
        end
      end
    end

    def ids(&)
      chest.oids { |oid| yield Id.from_oid oid }
    end

    def ids
      chest.oids.map { |oid| Id.from_oid oid }
    end

    def get(present : Array(String), absent : Array(String) = [] of String, limit : UInt32 = UInt32::MAX, from : Id? = nil)
      (index.find present, absent, limit, (from ? from.to_bytes : nil)).map { |b| Id.from_bytes b }
    end
  end
end
