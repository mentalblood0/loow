require "yaml"
require "json"

macro mserializable
  include YAML::Serializable
  include YAML::Serializable::Strict
  include JSON::Serializable
  include JSON::Serializable::Strict
end

macro mjyd(d, *nn)
  use_yaml_discriminator "{{d}}", {
    {% for n in nn %}
      {{n}}: {{n.stringify.camelcase.id}},
    {% end %}
  }
  use_json_discriminator "{{d}}", {
    {% for n in nn %}
      {{n}}: {{n.stringify.camelcase.id}},
    {% end %}
  }
end

macro dc(t, n, a, b)
  class {{n.stringify.camelcase.id}} < Command({{t}})
    mserializable

    getter args : {{a}}

    def_equals_and_hash @action, @args

    def initialize(@args)
      @action = "{{n}}"
    end

    def exec(s : T)
      {{b}}
    end
  end
end

module Wool
  def self.to_tj(v)
    t = v.class.name.rpartition(':').last.underscore
    JSON.parse ({"type" => t, t => v}).to_json
  end

  def self.from_tj(c, j)
    t = c.name.rpartition(':').last.underscore
    raise Exception.new "Can not parse #{c} from JSON marked \"#{c}\"" unless j["type"] == t
    c.from_json j[t].to_json
  end
end
