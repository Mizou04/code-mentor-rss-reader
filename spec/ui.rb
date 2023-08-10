require "rss"
require "rspec"

RSpec.describe RSS::UI, "#ask" do
  context "asks for url" do
    it "push url to urls array" do
      ui = RSS::UI.new(STDOUT)
      expect(ui.ask).to match(/valid/)
	end
  end
end
