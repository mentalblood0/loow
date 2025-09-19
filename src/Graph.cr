require "./Sweater"

module Wool
  class Graph
    enum Externalize
      None    = 0
      Related = 1
      All     = 2
    end

    alias Config = {wrap_width: UInt16, externalize_relations_nodes: Externalize}

    getter sweater : Sweater
    getter config : Config

    def initialize(@sweater, @config)
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
      @sweater.chest.objects do |oid, o|
        id = Id.from_oid oid
        ids = id.to_string
        c = Content.from_json o["content"].to_json
        t = @sweater.index.get id.to_bytes
        tags = (t.size > 0) ? wrap (t.join ' '), @config[:wrap_width] : nil
        case c
        when String
          text = wrap c, @config[:wrap_width]
          label = tags ? "{#{text}|#{tags}}" : text
          io << "\n\t\"#{id.to_string}\" [label=\"#{label}\", shape=record, style=bold];"
        when Relation
          text = wrap (c[:type].to_s.underscore.gsub '_', ' '), @config[:wrap_width]
          label = tags ? "{#{text}|#{tags}}" : text
          fids = c[:from].to_string
          tids = c[:to].to_string
          iids = "#{fids} -> #{tids}"
          if (@config[:externalize_relations_nodes] == Externalize::All) || (
               @config[:externalize_relations_nodes] == Externalize::Related && (
                 (@sweater.chest.unique "content.from", id.to_string) ||
                 (@sweater.chest.unique "content.to", id.to_string)
               )
             )
            io << "\n\t\"#{iids}\" [label=\"\", style=invis, fixedsize=\"false\", width=0, height=0, shape=none]"
            io << "\n\t\"#{fids}\" -> \"#{iids}\" [arrowhead=none];"
            io << "\n\t\"#{iids}\" -> \"#{tids}\";"
            io << "\n\t\"#{ids}\" [label=\"#{label}\", shape=record, style=dashed];"
            io << "\n\t\"#{iids}\" -> \"#{ids}\" [dir=none, style=dotted];"
          else
            io << "\n\t\"#{ids}\" [label=\"#{label}\", shape=record, style=dashed]"
            io << "\n\t\"#{fids}\" -> \"#{ids}\" [arrowhead=none];"
            io << "\n\t\"#{ids}\" -> \"#{tids}\";"
          end
        end
      end
      io << "\n}"
    end
  end
end
