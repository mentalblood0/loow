require "spec"

require "../src/Command"
require "../src/Graph"

rnd = Random.new 0

describe Wool do
  sweater = Wool::Sweater.from_yaml File.read "spec/config.yml"

  it "generative" do
    tt = {} of Wool::Id => Wool::Thesis
    i = 0
    until i == 100
      case rnd.rand 0..3
      when 0
        c = rnd.hex 17
        id = Wool::Command::Add.new({c: c}).exec sweater
        tt[id] = {content:   c,
                  relations: {from: Set(Wool::Id).new,
                              to: Set(Wool::Id).new},
                  tags: Set(String).new}
      when 1
        from = (tt.sample rnd rescue next)[0]
        to = (tt.sample rnd)[0]
        c = {from: from,
             to:   to,
             type: Wool::Type.values.sample rnd}
        id = Wool::Command::Add.new({c: c}).exec sweater
        tt[id] = {content:   c,
                  relations: {from: Set(Wool::Id).new,
                              to: Set(Wool::Id).new},
                  tags: Set(String).new}
        tt[from][:relations][:from] << id
        tt[to][:relations][:to] << id
      when 2
        id = (tt.sample rnd rescue next)[0]
        tags = Array.new (rnd.rand 1..8) { rnd.hex 1 }
        Wool::Command::AddTags.new({id: id, tags: tags}).exec sweater
        tt[id][:tags].concat tags
      when 3
        id = (tt.sample rnd rescue next)[0]
        tags = tt[id][:tags].sample (rnd.rand 1..8), rnd rescue next
        Wool::Command::DeleteTags.new({id: id, tags: tags}).exec sweater
        tt[id][:tags].subtract tags
      end
      sweater.ids.sort.should eq tt.keys.sort
      tt.each do |id, t|
        (Wool::Command::Get.new({id: id}).exec sweater).should eq t
      end
      i += 1
    end

    gio = IO::Memory.new
    g = Wool::Graph.new sweater, wrap: 20
    g.write gio
    puts gio.to_s
  end
end
