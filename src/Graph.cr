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
      s = id.to_string
      String.build { |r| (0..s.size - 3).step(6).each { |i| r << "<font color=\"##{s[i..i + 5]}\">▇</font>" } }
    end

    def write(io : IO)
      io << "digraph sweater {"
      @sweater.chest.objects do |id, o|
        next unless o["type"] == "thesis"
        sid = id.to_string
        c = Content.from_json o["thesis"]["content"].to_json
        tags = ((Set(String).new o["tags"].as_h.keys) rescue Set(String).new)
        show_id = (@config[:nodes_ids] == NodesIds::All) || ((@config[:nodes_ids] == NodesIds::Mentioned) &&
                                                             @sweater.chest.where({"mention.what" => sid}))
        hl = [] of String
        hl << to_colors id if show_id
        hl << wrap (tags.map { |t| "##{t}" }.join ' '), @config[:wrap_width] unless tags.empty?
        h = hl.empty? ? nil : hl.join "<br/>"
        case c
        when String
          text = (wrap c, @config[:wrap_width]).gsub /{[^{}]+}/ { |s| to_colors Id.from_string s[1..s.size - 2] }
          label = <<-HTML
          <TABLE BORDER="2" CELLSPACING="0" CELLPADDING="8">
            #{"<TR><TD BORDER=\"1\" SIDES=\"b\">#{h}</TD></TR>" if h}
            <TR><TD BORDER="0">#{text}</TD></TR>
          </TABLE>
          HTML
          io << "\n\t\"#{sid}\" [label=<#{label}>, shape=plaintext];"
          c.scan /{([^{}]+)}/ do |m|
            mid = Id.from_string m[1]
            io << "\n\t\"#{sid}\" -> \"#{mid.to_string}\" [arrowhead=none, color=\"grey\" style=dotted];"
          end
        when Relation
          text = wrap (c[:type].to_s.underscore.gsub '_', ' '), @config[:wrap_width]
          label = <<-HTML
          <TABLE CELLSPACING="0" STYLE="dashed">
            #{"<TR><TD SIDES=\"b\" STYLE=\"dashed\">#{h}</TD></TR>" if h}
            <TR><TD BORDER="0">#{text}</TD></TR>
          </TABLE>
          HTML
          fsid = c[:from].to_string
          tsid = c[:to].to_string
          isid = "#{fsid} -> #{tsid}"
          if (@config[:externalize_relations_nodes] == Externalize::All) || (
               @config[:externalize_relations_nodes] == Externalize::Related && (
                 (@sweater.chest.where({"thesis.content.from" => sid})) ||
                 (@sweater.chest.where({"thesis.content.to" => sid}))
               )
             )
            io << "\n\t\"#{isid}\" [label=\"\", style=invis, fixedsize=\"false\", width=0, height=0, shape=none]"
            io << "\n\t\"#{fsid}\" -> \"#{isid}\" [dir=back, arrowtail=tee];"
            io << "\n\t\"#{isid}\" -> \"#{tsid}\";"
            io << "\n\t\"#{sid}\" [label=<#{label}>, shape=plaintext];"
            io << "\n\t\"#{isid}\" -> \"#{sid}\" [dir=none, style=dotted];"
          else
            io << "\n\t\"#{sid}\" [label=<#{label}>, shape=plaintext]"
            io << "\n\t\"#{fsid}\" -> \"#{sid}\" [dir=back, arrowtail=tee];"
            io << "\n\t\"#{sid}\" -> \"#{tsid}\";"
          end
        end
      end
      io << "\n}"
    end
  end
end
