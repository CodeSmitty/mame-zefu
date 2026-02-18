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
    this.boundHandleVisibilityChange =
      this.boundHandleVisibilityChange || this.handleVisibilityChange.bind(this)
    document.addEventListener(
      "visibilitychange",
      this.boundHandleVisibilityChange,
    )
  }

  disconnect() {
    this.releaseWakeLock()
    if (this.boundHandleVisibilityChange) {
      document.removeEventListener(
        "visibilitychange",
        this.boundHandleVisibilityChange,
      )
    }
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

    } catch (err) {
      console.error(`Failed to acquire wake lock: ${err.name}, ${err.message}`)
      this.checkboxTarget.checked = false
    }
  }

  async releaseWakeLock() {
    if (this.wakeLock) {
      try {
        await this.wakeLock.release()
        this.wakeLock = null

        // Clear preference
        localStorage.removeItem("wakeLock")
      } catch (err) {
        console.error(`Failed to release wake lock: ${err.name}, ${err.message}`)
      }
    }
  }

  handleVisibilityChange() {
    if (this.checkboxTarget.checked && document.visibilityState === "visible") {
      // Re-acquire wake lock when page becomes visible again
      this.requestWakeLock()
    }
  }
}
