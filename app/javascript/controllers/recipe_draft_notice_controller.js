import { Controller } from "@hotwired/stimulus"
import {
  hasRecipeDraft,
  removeRecipeDraft,
  storageAvailable,
} from "controllers/recipe_draft_storage"

export default class extends Controller {
  static values = {
    storageKey: String,
  }

  static targets = ["notice"]

  connect() {
    if (!storageAvailable()) return

    this.toggleNotice(this.hasStoredDraft())
  }

  clearAndReload(event) {
    event.preventDefault()
    if (!this.hasStorageKeyValue || this.storageKeyValue.length === 0) return

    removeRecipeDraft(this.storageKeyValue)

    if (window.Turbo && typeof window.Turbo.visit === "function") {
      window.Turbo.visit(window.location.href, { action: "replace" })
    } else {
      window.location.reload()
    }
  }

  hasStoredDraft() {
    if (!this.hasStorageKeyValue || this.storageKeyValue.length === 0)
      return false

    return hasRecipeDraft(this.storageKeyValue)
  }

  toggleNotice(visible) {
    if (!this.hasNoticeTarget) return

    this.noticeTarget.hidden = !visible
  }
}
