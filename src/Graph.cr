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
          fid = c[:from].to_string
          tid = c[:to].to_string
          iid = "#{fid} -> #{tid}"
          io << "\n\t\"#{iid}\" [label=\"\", style=invis, fixedsize=\"false\", width=0, height=0, shape=none]"
          io << "\n\t\"#{fid}\" -> \"#{iid}\" [arrowhead=none];"
          io << "\n\t\"#{iid}\" -> \"#{tid}\";"
          io << "\n\t\"#{id}\" [label=\"#{label}\", shape=ellipse];"
          io << "\n\t\"#{iid}\" -> \"#{id}\" [dir=none, style=dotted];"
        end
      end
      io << "\n}"
    end
  end
end
