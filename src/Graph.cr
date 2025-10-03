require "./Sweater"

module Wool
  class Graph
    enum Externalize
      None
      Related
      All
    end

    enum NodesIds
      None
      Mentioned
      All
    end

    alias Config = {wrap_width: UInt16, externalize_relations_nodes: Externalize, nodes_ids: NodesIds}

    getter sweater : Sweater
    getter config : Config

    def initialize(@sweater, @config)
    end

    protected def wrap(text : String, width : UInt16)
      words = text.split
      lines = [] of String
      current_line = ""
      current_line_size = 0

      words.each do |word|
        word_size = (word.match /{[^{}]+}/) ? 5 : word.size
        if current_line.empty?
          current_line = word
          current_line_size = word_size
        elsif current_line_size + 1 + word_size <= width
          current_line += " " + word
          current_line_size += 1 + word_size
        else
          lines << current_line
          current_line = word
          current_line_size = word_size
        end
      end

      lines << current_line unless current_line.empty?
      lines.join "<br/>"
    end

    def to_colors(id : Id)
      s = id.string
      String.build { |r| (0..s.size - 3).step(6).each { |i| r << "<font color=\"##{s[i..i + 5]}\">▇</font>" } }
    end

    def write(io : IO)
      io << "digraph sweater {"
      @sweater.chest.objects do |id, o|
        th = Wool.from_tj Thesis, o rescue next
        show_id = (@config[:nodes_ids] == NodesIds::All) || ((@config[:nodes_ids] == NodesIds::Mentioned) &&
                                                             @sweater.chest.where({"mention.what" => id.string}))
        hl = [] of String
        hl << to_colors id if show_id
        hl << wrap (th.tags.map { |t| "##{t}" }.join ' '), @config[:wrap_width] unless th.tags.empty?
        h = hl.empty? ? nil : hl.join "<br/>"
        case c = th.content
        when Text
          text = (wrap c.value, @config[:wrap_width]).gsub /{[^{}]+}/ { |s| to_colors Id.from_string s[1..s.size - 2] }
          label = <<-HTML
          <TABLE BORDER="2" CELLSPACING="0" CELLPADDING="8">
            #{"<TR><TD BORDER=\"1\" SIDES=\"b\">#{h}</TD></TR>" if h}
            <TR><TD BORDER="0">#{text}</TD></TR>
          </TABLE>
          HTML
          io << "\n\t\"#{id.string}\" [label=<#{label}>, shape=plaintext];"
          c.value.scan /{([^{}]+)}/ do |m|
            mid = Id.from_string m[1]
            io << "\n\t\"#{id.string}\" -> \"#{mid.string}\" [arrowhead=none, color=\"grey\" style=dotted];"
          end
        when Relation
          label = <<-HTML
          <TABLE CELLSPACING="0" STYLE="dashed">
            #{"<TR><TD SIDES=\"b\" STYLE=\"dashed\">#{h}</TD></TR>" if h}
            <TR><TD BORDER="0">#{c.type.name}</TD></TR>
          </TABLE>
          HTML
          isid = "#{c.from.string} -> #{c.to.string}"
          if (@config[:externalize_relations_nodes] == Externalize::All) || (
               @config[:externalize_relations_nodes] == Externalize::Related && (
                 (@sweater.chest.where({"thesis.content.from" => id.string})) ||
                 (@sweater.chest.where({"thesis.content.to" => id.string}))
               )
             )
            io << "\n\t\"#{isid}\" [label=\"\", style=invis, fixedsize=\"false\", width=0, height=0, shape=none]"
            io << "\n\t\"#{c.from.string}\" -> \"#{isid}\" [dir=back, arrowtail=tee];"
            io << "\n\t\"#{isid}\" -> \"#{c.to.string}\";"
            io << "\n\t\"#{id.string}\" [label=<#{label}>, shape=plaintext];"
            io << "\n\t\"#{isid}\" -> \"#{id.string}\" [dir=none, style=dotted];"
          else
            io << "\n\t\"#{id.string}\" [label=<#{label}>, shape=plaintext]"
            io << "\n\t\"#{c.from.string}\" -> \"#{id.string}\" [dir=back, arrowtail=tee];"
            io << "\n\t\"#{id.string}\" -> \"#{c.to.string}\";"
          end
        end
      end
      io << "\n}"
    end
  end
end
