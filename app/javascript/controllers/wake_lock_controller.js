import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    this.wakeLock = null
    this.isSupported = "wakeLock" in navigator

    // Check if we should enable wake lock based on stored preference
    const storedPreference = localStorage.getItem("wakeLock")

    if (!this.isSupported) {
      // Hide the toggle if wake lock is not supported
      this.element.style.display = "none"
      return
    }

    // Restore previous state if user had it enabled
    if (storedPreference === "true") {
      this.checkboxTarget.checked = true
      this.requestWakeLock()
    }

    // Re-acquire wake lock when page becomes visible again
    document.addEventListener(
      "visibilitychange",
      this.handleVisibilityChange.bind(this),
    )
  }

  disconnect() {
    this.releaseWakeLock()
    document.removeEventListener(
      "visibilitychange",
      this.handleVisibilityChange.bind(this),
    )
  }

  async toggle() {
    if (this.checkboxTarget.checked) {
      await this.requestWakeLock()
    } else {
      this.releaseWakeLock()
    }
  }

  async requestWakeLock() {
    if (!this.isSupported) return

    try {
      this.wakeLock = await navigator.wakeLock.request("screen")

      // Save preference
      localStorage.setItem("wakeLock", "true")

      // this.wakeLock.addEventListener("release", () => {
      //   console.log("Wake lock released")
      // })

      // console.log("Wake lock acquired")
    } catch (err) {
      console.error(`Failed to acquire wake lock: ${err.name}, ${err.message}`)
    }
  }

  releaseWakeLock() {
    if (this.wakeLock) {
      this.wakeLock.release()
      this.wakeLock = null

      // Clear preference
      localStorage.removeItem("wakeLock")
    }
  }

  handleVisibilityChange() {
    if (this.wakeLock !== null && document.visibilityState === "visible") {
      // Re-acquire wake lock when page becomes visible again
      this.requestWakeLock()
    }
  }
}
