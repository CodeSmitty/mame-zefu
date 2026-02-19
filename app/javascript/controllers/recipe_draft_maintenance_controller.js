import { Controller } from "@hotwired/stimulus"
import {
  runRecipeDraftMaintenance,
  storageAvailable,
} from "./recipe_draft_storage"

export default class extends Controller {
  connect() {
    if (!storageAvailable()) return

    runRecipeDraftMaintenance()
  }
}
