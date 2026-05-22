class WdydtAgent < Formula
  desc "Mac agent for lvr-wdydt-app — pushes ActivityWatch + Claude Code sessions"
  homepage "https://wdydt.golocalvr.com"
  url "https://github.com/LVRHQ/lvr-wdydt-app/releases/download/v0.1.0/wdydt-agent-0.1.0.tar.gz"
  sha256 "c7b3a73057f8ff318ac90e6a2009bf909c07f2f745dff6ed0961c4975e8c018f"
  license "Proprietary"
  version "0.1.0"

  depends_on "node"
  depends_on cask: "activitywatch"

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

  def post_install
    plist_dir = Pathname.new("#{ENV["HOME"]}/Library/LaunchAgents")
    plist_dir.mkpath

    {
      "com.golocalvr.wdydt.activity.plist"  => "push-activity",
      "com.golocalvr.wdydt.sessions.plist"  => "push-sessions",
    }.each do |plist_name, command|
      src = libexec/"launchd"/plist_name
      next unless src.exist?
      dest = plist_dir/plist_name
      next if dest.exist?  # don't clobber user customizations on upgrade
      content = src.read
        .gsub("__BIN__", bin/"wdydt-agent")
        .gsub("__LOG_DIR__", "#{ENV["HOME"]}/.wdydt/logs")
        .gsub("__COMMAND__", command)
      dest.write(content)
    end

    (Pathname.new("#{ENV["HOME"]}/.wdydt")/"logs").mkpath
  end

  def caveats
    <<~EOS
      Next steps:

        1. Sign in to WDYDT at https://wdydt.golocalvr.com and grab your API
           token (Step 2 of the onboarding wizard).
        2. Save it to ~/.wdydt/config.json:
             {"api_token": "wdydt_PASTE_HERE"}
        3. Open ActivityWatch.app so the window/AFK watchers start.
        4. Grant Input Monitoring permission to wdydt-input if you want
           keystroke + mouse counts:
             System Settings → Privacy & Security → Input Monitoring
        5. Load the launchd jobs:
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
