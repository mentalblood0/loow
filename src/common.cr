require "yaml"
require "json"

macro mserializable
  include YAML::Serializable
  include YAML::Serializable::Strict
  include JSON::Serializable
  include JSON::Serializable::Strict
end

module Wool
  def self.to_tj(v)
    t = v.class.name.camelcase
    JSON.parse ({"type" => t, t => v}).to_json
  end

  def self.from_tj(c, j)
    t = c.name.camelcase
    raise Exception.new "Can not parse #{c} from JSON marked \"#{c}\"" unless j["type"] == t
    c.from_json j[t].to_json
  end
end
