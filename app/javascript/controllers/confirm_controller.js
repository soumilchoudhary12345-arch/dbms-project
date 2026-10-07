import { Controller } from "@hotwired/stimulus"

// Asks for confirmation before the form that starts a quiz session is submitted.
export default class extends Controller {
  static targets = ["start", "dialog"]

  guard(event) {
    if (typeof this.dialogTarget.showModal !== "function") return
    event.preventDefault()
    this.dialogTarget.showModal()
  }

  cancel() {
    this.dialogTarget.close()
  }

  accept() {
    this.dialogTarget.close()
    this.startTarget.form.requestSubmit()
  }
}
