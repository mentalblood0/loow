require "./Sweater"

module Wool
  class Graph
    getter sweater : Sweater

    def initialize(@sweater)
    end

    def write(io : IO)
      io << "digraph sweater {"
      @sweater.chest.oids do |oid|
        c = Content.from_json (@sweater.chest.get oid).not_nil!["content"].to_json
        id = (Id.from_oid oid).to_string
        case c
        when String
          io << "\n\t\"#{id}\" [label=\"#{c}\", shape=box];"
        when Relation
          label = c[:type].to_s.underscore.gsub '_', ' '
          io << "\n\t\"#{id}\" [label=\"#{label}\", shape=ellipse];"
          io << "\n\t\"#{c[:from].to_string}\" -> \"#{id}\" -> \"#{c[:to].to_string}\";"
        end
      end
      io << "\n}"
    end
  end
end
