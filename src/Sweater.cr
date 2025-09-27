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
  alias Mention = {what: Id, where: Id}

  class Sweater
    include YAML::Serializable
    include YAML::Serializable::Strict

    getter relations_types : Set(String)
    getter chest : Trove::Chest
    getter index : Dream::Index

    def add(c : Content)
      id = Id.from_content c
      raise Exception.new "Content already exists" if @chest.has_key! id.to_oid, "type"

      case c
      when Relation
        raise Exception.new "Relation type \"#{c[:type]}\" is not allowed in this Sweater" unless @relations_types.includes? c[:type]
        raise Exception.new "No \"from\" id #{c[:from].to_string} for relation" unless chest.has_key? c[:from].to_oid
        raise Exception.new "No \"to\" id #{c[:to].to_string} for relation" unless chest.has_key? c[:to].to_oid
      when String
        c.scan /{([^{}]+)}/ do |m|
          mentioned_id = Id.from_string m[1]
          mention_id = Id.from_ids id, mentioned_id
          @chest.set mention_id.to_oid, "", JSON.parse({type:    "mention",
                                                        mention: {what: mentioned_id.to_string,
                                                                  where: id.to_string}}.to_json)
        end
      end

      @chest.set id.to_oid, "", JSON.parse({type: "thesis", thesis: {content: c}}.to_json)
      id
    end

    def add(id : Id, tags : Array(String))
      @index.add id.to_bytes, tags
    end

    def delete(id : Id, tags : Array(String))
      @index.delete id.to_bytes, tags
    end

    def get(id : Id) : Thesis?
      {content:   (Content.from_json (@chest.get id.to_oid).not_nil!["thesis"]["content"].to_json rescue return nil),
       relations: {from: (Set.new (@chest.where "thesis.content.from", id.to_string).map { |oid| Id.from_oid oid }),
                   to: (Set.new (@chest.where "thesis.content.to", id.to_string).map { |oid| Id.from_oid oid })},
       tags: Set.new @index.get id.to_bytes}
    end

    def get(c : Content) : Thesis?
      get Id.from_content c
    end

    def delete(id : Id)
      @chest.transaction do |ctx|
        @index.transaction do |itx|
          ["from", "to"].each do |p|
            @chest.where "thesis.content.#{p}", id.to_string do |oid|
              ctx.delete oid
              itx.delete (Id.from_oid oid).to_bytes
            end
          end
        end
      end
    end

    def ids(&)
      @chest.oids { |oid| yield Id.from_oid oid }
    end

    def ids
      @chest.oids.map { |oid| Id.from_oid oid }
    end

    def get(present : Array(String), absent : Array(String) = [] of String, limit : UInt32 = UInt32::MAX, from : Id? = nil)
      (@index.find present, absent, limit, (from ? from.to_bytes : nil)).map { |b| Id.from_bytes b }
    end
  end
end
