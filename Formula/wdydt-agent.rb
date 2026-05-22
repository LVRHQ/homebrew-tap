class WdydtAgent < Formula
  desc "Mac agent for lvr-wdydt-app — pushes ActivityWatch + Claude Code sessions"
  homepage "https://lvr-wdydt-app.vercel.app"
  url "https://github.com/LVRHQ/homebrew-tap/releases/download/v0.1.2/wdydt-agent-0.1.2.tar.gz"
  sha256 "6ca6d7369ff1e396bb4ed9131d7b5bedbf83a28ca8be4a99f50cb515ba96dcd1"
  license "Proprietary"
  version "0.1.2"

  depends_on "node"

  def install
    libexec.install Dir["*"]
    (bin/"wdydt-agent").write <<~SH
      #!/bin/bash
      set -e
      case "$1" in
        push-activity)
          shift
          exec /usr/bin/env node "#{libexec}/push-activity.mjs" "$@"
          ;;
        push-sessions)
          shift
          exec /usr/bin/env node "#{libexec}/push-sessions.mjs" "$@"
          ;;
        setup)
          exec "#{libexec}/setup.sh"
          ;;
        *)
          echo "Usage: wdydt-agent {push-activity|push-sessions|setup} [args...]"
          exit 1
          ;;
      esac
    SH
    chmod 0755, bin/"wdydt-agent"
  end

  # No post_install — writing to ~/Library/LaunchAgents from a brew context
  # gets blocked by macOS TCC on Sequoia+. `wdydt-agent setup` runs the same
  # work from the user's shell, which has the right permissions.

  def caveats
    <<~EOS
      Next steps:

        0. Install ActivityWatch if you don't already have it:
             brew install --cask activitywatch
        1. Run the interactive setup (saves your token, installs launchd jobs):
             wdydt-agent setup
        2. Open ActivityWatch.app so the window/AFK watchers start.
        3. Load the launchd jobs (setup prints these commands too):
             launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.golocalvr.wdydt.activity.plist
             launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.golocalvr.wdydt.sessions.plist

      Logs land in ~/.wdydt/logs/.
    EOS
  end

  test do
    assert_predicate bin/"wdydt-agent", :exist?
    output = shell_output("#{bin}/wdydt-agent 2>&1", 1)
    assert_match "Usage: wdydt-agent", output
  end
end
