module FixtureHelpers
  def load_fixture_file(filename)
    File.open(File.join(File.dirname(__FILE__), "..", "fixtures", filename), encoding: "utf-8")
  end
end
