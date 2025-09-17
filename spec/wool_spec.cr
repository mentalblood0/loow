require "spec"

require "../src/wool"

rnd = Random.new 0

describe Wool do
  sweater = Wool::Sweater.from_yaml File.read "spec/config.yml"

  it "generative" do
    tt = {} of Wool::Id => Wool::Thesis
    100.times do
      case rnd.rand 0..3
      when 0
        c = rnd.hex 17
        id = sweater.add c

        ::Log.debug { "add #{c} => #{id}" }

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
        id = sweater.add c

        ::Log.debug { "add #{c} => #{id}" }

        tt[id] = {content:   c,
                  relations: {from: Set(Wool::Id).new,
                              to: Set(Wool::Id).new},
                  tags: Set(String).new}
        tt[from][:relations][:from] << id
        tt[to][:relations][:to] << id
      when 2
        id = (tt.sample rnd rescue next)[0]
        tags = Array.new (rnd.rand 1..8) { rnd.hex 1 }
        sweater.add id, tags

        ::Log.debug { "add #{id} #{tags}" }

        tt[id][:tags].concat tags
      when 3
        id = (tt.sample rnd rescue next)[0]
        tags = tt[id][:tags].sample (rnd.rand 1..8), rnd rescue next
        sweater.delete id, tags

        ::Log.debug { "delete #{id} #{tags}" }

        tt[id][:tags].subtract tags
      end
      tt.each do |id, t|
        (sweater.get id).should eq t
      end
    end
  end
end
