require "./Sweater"

module Wool
  class Graph
    getter sweater : Sweater
    getter wrap : UInt16

    def initialize(@sweater, @wrap)
    end

    protected def wrap(text : String, width : UInt16)
      words = text.split
      lines = [] of String
      current_line = ""

      words.each do |word|
        if current_line.empty?
          current_line = word
        elsif current_line.size + word.size + 1 <= width
          current_line += " " + word
        else
          lines << current_line
          current_line = word
        end
      end

      lines << current_line unless current_line.empty?
      lines.join "\\n"
    end

    def write(io : IO)
      io << "digraph sweater {"
      @sweater.chest.oids do |oid|
        id = Id.from_oid oid
        ids = id.to_string
        c = Content.from_json (@sweater.chest.get oid).not_nil!["content"].to_json
        t = @sweater.index.get id.to_bytes
        tags = (t.size > 0) ? wrap (t.join ' '), @wrap_width : nil
        case c
        when String
          text = wrap c, @wrap_width
          label = tags ? "{#{text}|#{tags}}" : text
          io << "\n\t\"#{id.to_string}\" [label=\"#{label}\", shape=record];"
        when Relation
          text = wrap (c[:type].to_s.underscore.gsub '_', ' '), @wrap_width
          label = tags ? "{#{text}|#{tags}}" : text
          fids = c[:from].to_string
          tids = c[:to].to_string
          iids = "#{fids} -> #{tids}"
          io << "\n\t\"#{iids}\" [label=\"\", style=invis, fixedsize=\"false\", width=0, height=0, shape=none]"
          io << "\n\t\"#{fids}\" -> \"#{iids}\" [arrowhead=none];"
          io << "\n\t\"#{iids}\" -> \"#{tids}\";"
          io << "\n\t\"#{ids}\" [label=\"#{label}\", shape=record, style=rounded];"
          io << "\n\t\"#{iids}\" -> \"#{ids}\" [dir=none, style=dotted];"
        end
      end
      io << "\n}"
    end
  end
end
