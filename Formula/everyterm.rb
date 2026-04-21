cask "everyterm" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/everyterm/everyterm/releases/download/v#{version}/EveryTerm-#{version}.dmg"
  name "EveryTerm"
  desc "Multi-protocol terminal and remote access client for macOS"
  homepage "https://github.com/everyterm/everyterm"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "EveryTerm.app"

  zap trash: [
    "~/Library/Application Support/EveryTerm",
    "~/Library/Caches/com.everyterm.app",
    "~/Library/Preferences/com.everyterm.app.plist",
  ]
end
