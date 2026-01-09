import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._abort = new AbortController()

    if (!this._onClickLink) this._onClickLink = this.onClickLink.bind(this)

    this.initializeObserver(this.element)
  }

  onClickLink(e) {
    const href = e.currentTarget.getAttribute("href")
    if (href) {
      e.preventDefault()

      const params = new URLSearchParams({ url: href })
      window.location.href = `web_result?${params}`
    }
  }

  initializeObserver(targetNode) {
    if (this._observer) return

    if (!this._onMutations)
      this._onMutations = this.searchResultsCallback.bind(this)

    const config = { attributes: false, childList: true, subtree: true }
    this._observer = new MutationObserver(this._onMutations)
    this._observer.observe(targetNode, config)
  }

  searchResultsCallback(mutationList) {
    for (const mutation of mutationList) {
      if (mutation.type === "childList") {
        for (const node of mutation.addedNodes) {
          if (!(node.nodeType === Node.ELEMENT_NODE)) continue

          if (node.matches("div.gsc-result")) {
            const links = node.querySelectorAll("a")
            for (const link of links) {
              link.addEventListener("click", this._onClickLink)
              link._boundToController = true
            }
          } else if (node.matches("div.gs-mobilePreview img.gs-imagePreview")) {
            const link = node.parentElement
            link.addEventListener("click", this._onClickLink)
            link._boundToController = true
          }
        }

        for (const node of mutation.removedNodes) {
          if (!(node.nodeType === Node.ELEMENT_NODE)) continue

          if (node.matches("div.gsc-result")) {
            const links = node.querySelectorAll("a")
            for (const link of links) {
              if (!link._boundToController) continue

              link.removeEventListener("click", this._onClickLink)
              delete link._boundToController
            }
          } else if (node.matches("div.gs-mobilePreview img.gs-imagePreview")) {
            const link = node.parentElement
            if (!link._boundToController) continue

            link.removeEventListener("click", this._onClickLink)
            delete link._boundToController
          }
        }
      }
    }
  }

  disconnect() {
    this._observer?.disconnect()
    this._abort?.abort()
  }
}
