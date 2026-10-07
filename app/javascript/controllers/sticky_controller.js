import { Controller } from "@hotwired/stimulus"

const KEY = "study-stickies"
const DEFAULTS = [
  "Ch 7 — drill by-parts on Q4–Q9 before Monday",
  "Revise vector identities (ch 10) Friday",
  ""
]

export default class extends Controller {
  static targets = ["note"]

  connect() {
    let saved = []
    try {
      saved = JSON.parse(localStorage.getItem(KEY)) || []
    } catch (_e) {
      saved = []
    }
    this.noteTargets.forEach((note, i) => {
      note.value = typeof saved[i] === "string" ? saved[i] : (DEFAULTS[i] || "")
    })
  }

  save() {
    localStorage.setItem(KEY, JSON.stringify(this.noteTargets.map((note) => note.value)))
  }
}
