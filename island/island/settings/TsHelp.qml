import QtQuick
import qs.services

// The Tailscale setup steps (shown from Hub › Tailscale › Set Up and Settings).
HelpCard {
    text: "1. Install it (Gentoo):\n" +
          "   doas emerge --ask net-vpn/tailscale\n\n" +
          "2. Start it now and at every boot (OpenRC):\n" +
          "   doas rc-service tailscale start\n" +
          "   doas rc-update add tailscale default\n\n" +
          "3. Let your user control it without doas (once per machine):\n" +
          "   doas tailscale set --operator=$USER\n" +
          "   Without this, the island can show everything but can't connect, " +
          "switch exit nodes or change options.\n\n" +
          "4. Log in: press Log In in the Tailscale panel (or run: tailscale up) " +
          "and finish in the browser.\n\n" +
          "Mullvad: if your tailnet has the Mullvad add-on and this device is allowed " +
          "to use it, Mullvad servers appear under Exit Node by themselves.\n\n" +
          "Status here: " + (!Tailscale.installed ? "tailscale not installed"
                            : !Tailscale.daemon ? "installed, tailscaled not running"
                            : Tailscale.isOperator ? "ready" : "running, operator not set (step 3)")
}
