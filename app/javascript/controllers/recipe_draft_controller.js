import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"
import {
  readRecipeDraft,
  removeRecipeDraft,
  storageAvailable,
  writeRecipeDraft,
} from "./recipe_draft_storage"

export default class extends Controller {
  static values = {
    storageKey: String,
  }

  connect() {
    if (!storageAvailable()) return
    if (!this.hasStorageKeyValue || this.storageKeyValue.length === 0) return

    this.persistenceEnabled = true

    this.draft = this.readDraft()

    this.restoreDraft()

    this.debouncedPersistDraft = debounce(() => this.persistDraft(), 300)
    this.boundHandleInput = this.handleInput.bind(this)
    this.boundHandleChange = this.handleChange.bind(this)

    this.element.addEventListener("input", this.boundHandleInput)
    this.element.addEventListener("change", this.boundHandleChange)
  }

  disconnect() {
    if (this.boundHandleInput) {
      this.element.removeEventListener("input", this.boundHandleInput)
    }

    if (this.boundHandleChange) {
      this.element.removeEventListener("change", this.boundHandleChange)
    }

    if (this.debouncedPersistDraft) {
      this.debouncedPersistDraft.cancel()
    }
  }

  submitEnd(event) {
    if (event.detail.success) {
      this.clearDraft()
    }
  }

  handleInput(event) {
    if (!this.persistenceEnabled) return
    this.clearOutlineHighlight(event.target)
    if (!this.updateDraftForElement(event.target)) return

    this.debouncedPersistDraft()
  }

  handleChange(event) {
    if (!this.persistenceEnabled) return
    this.clearOutlineHighlight(event.target)
    if (!this.updateDraftForElement(event.target)) return

    this.debouncedPersistDraft.cancel()
    this.persistDraft()
  }

  persistDraft() {
    if (!this.persistenceEnabled) return

    try {
      writeRecipeDraft(this.storageKeyValue, this.draft)
      this.clearAllOutlineHighlights()
    } catch (error) {
      console.error(
        "Failed to persist recipe draft, auto-save has been disabled:",
        error,
      )
      this.disablePersistence()
      this.draft = {}
    }
  }

  restoreDraft() {
    const draft = this.draft
    if (!draft || Object.keys(draft).length === 0) return false

    this.formElements().forEach((element) => {
      if (this.isIgnoredField(element)) return
      if (!(element.name in draft)) return

      const value = this.normalizedFieldValue(draft[element.name])

      if (!this.valuesEqual(element.value, value)) {
        this.applyOutlineHighlight(element)
      }

      element.value = value
    })

    return true
  }

  clearDraft() {
    if (this.debouncedPersistDraft) {
      this.debouncedPersistDraft.cancel()
    }

    this.draft = {}
    if (this.persistenceEnabled) {
      removeRecipeDraft(this.storageKeyValue)
    }
  }

  disablePersistence() {
    this.persistenceEnabled = false

    if (this.debouncedPersistDraft) {
      this.debouncedPersistDraft.cancel()
    }
  }

  readDraft() {
    return readRecipeDraft(this.storageKeyValue)
  }

  formElements() {
    return Array.from(this.element.elements)
  }

  isIgnoredField(element) {
    if (!element?.name) return true

    const ignoredNames = ["authenticity_token", "commit", "utf8", "_method"]
    if (ignoredNames.includes(element.name)) return true

    const ignoredTypes = [
      "file",
      "hidden",
      "submit",
      "button",
      "image",
      "reset",
      "checkbox",
      "radio",
    ]
    if (ignoredTypes.includes(element.type)) return true

    const ignoredTagNames = ["SELECT"]
    if (ignoredTagNames.includes(element.tagName)) return true

    return false
  }

  updateDraftForElement(element) {
    if (this.isIgnoredField(element)) return false

    this.draft[element.name] = this.normalizedFieldValue(element.value)
    return true
  }

  valuesEqual(left, right) {
    return this.normalizedFieldValue(left) === this.normalizedFieldValue(right)
  }

  normalizedFieldValue(value) {
    if (value === null || value === undefined) return ""

    return String(value)
  }

  applyOutlineHighlight(element) {
    element.style.outline = "2px solid rgb(239 68 68)"
    element.style.outlineOffset = "1px"
  }

  clearOutlineHighlight(element) {
    if (!element) return

    element.style.outline = ""
    element.style.outlineOffset = ""
  }

  clearAllOutlineHighlights() {
    this.formElements().forEach((element) => {
      this.clearOutlineHighlight(element)
    })
  }
}
