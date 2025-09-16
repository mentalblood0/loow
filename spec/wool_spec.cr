require "spec"

require "../src/wool"

rnd = Random.new 0

describe Wool do
  sweater = Wool::Sweater.from_yaml File.read "spec/config.yml"

  it "generative" do
    tt = {} of Wool::Id => {content: Wool::Content, tags: Set(String)}
    100.times do
      case rnd.rand 0..1
      when 0
        c = rnd.hex 16
        id = sweater.add c
        tt[id] = {content: c, tags: Set(String).new}
      when 1
        id = (tt.sample rnd rescue next)[0]
        tags = Array.new (rnd.rand 1..8) { rnd.hex 1 }
        sweater.add id, tags
        tt[id][:tags].concat tags
      end
      tt.each do |id, t|
        (sweater.get id).should eq t
      end
    end
  end
end
