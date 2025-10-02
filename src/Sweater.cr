require "yaml"

require "trove"
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

    def add(c : Content)
      id = Id.from_content c
      raise Exception.new "Content #{c} already exists" if @chest.has_key! id, "type"

      case c
      when Relation
        raise Exception.new "Relation type \"#{c[:type]}\" is not allowed in this Sweater" unless @relations_types.includes? c[:type]
        raise Exception.new "No \"from\" id #{c[:from].to_string} for relation" unless chest.has_key! c[:from], "type"
        raise Exception.new "No \"to\" id #{c[:to].to_string} for relation" unless chest.has_key! c[:to], "type"
      when String
        c.scan /{([^{}]+)}/ do |m|
          mentioned_id = Id.from_string m[1]
          mention_id = Id.from_ids id, mentioned_id
          @chest.set mention_id, "", JSON.parse({type:    "mention",
                                                 mention: {what: mentioned_id.to_string,
                                                           where: id.to_string}}.to_json)
        end
      end

      @chest.set id, "", JSON.parse({type: "thesis", thesis: {content: c}}.to_json)
      id
    end

    def add(id : Id, tags : Array(String))
      @chest.transaction do |tx|
        tags.each { |t| @chest.set! id, "tags.#{t}", JSON::Any.new nil }
      end
    end

    def delete(id : Id, tags : Array(String))
      @chest.transaction do |tx|
        tags.each { |t| @chest.delete! id, t }
      end
    end

    def get(id : Id) : Thesis?
      r = (@chest.get id).not_nil!["thesis"] rescue return nil
      {content:   (Content.from_json r["content"].to_json),
       relations: {from: (Set.new @chest.where({"thesis.content.from" => id.to_string})),
                   to: (Set.new @chest.where({"thesis.content.to" => id.to_string}))},
       tags: ((Set(String).new r["tags"].as_h.keys rescue Set(String).new))}
    end

    def get(c : Content) : Thesis?
      get Id.from_content c
    end

    def delete(id : Id)
      @chest.transaction do |tx|
        tx.where({"thesis.content.#{p}" => id.to_string}) do |oid|
          tx.delete oid
        end
      end
    end

    def get(present : Array(String), absent : Array(String) = [] of String, from : Id? = nil, &)
      @chest.where(
        (Hash.zip present.map { |t| "tags.#{t}" }, (Array.new(present.size) { nil })),
        (Hash.zip absent.map { |t| "tags.#{t}" }, (Array.new(absent.size) { nil })),
        from) { |o| yield o }
    end

    def get(present : Array(String), absent : Array(String) = [] of String, from : Id? = nil, limit : UInt64 = UInt64::MAX)
      r = [] of Id
      get(present, absent, from) do |o|
        break if r.size == limit
        r << o
      end
      r
    end
  end
end
