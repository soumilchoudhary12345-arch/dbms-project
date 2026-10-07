import { Controller } from "@hotwired/stimulus"

// Click a selected option once to select, again to clear it.
// Radios natively refuse to uncheck, so we intercept: remember the checked
// state before the click (pointerdown/keydown), and if this click found it
// already checked, clear it and cancel the default so a wrapping label
// doesn't immediately re-check it.
export default class extends Controller {
  inputFor(target) {
    if (!(target instanceof Element)) return null
    if (target.matches('input[type="radio"]')) return target
    const label = target.closest("label")
    return label ? label.control : null
  }

  remember(event) {
    const input = this.inputFor(event.target)
    if (input) this.wasChecked = input.checked
  }

  select(event) {
    const input = this.inputFor(event.target)
    if (!input) return

    if (input.checked && this.wasChecked) {
      // Cancel only label-activation: a click on the radio itself must NOT be
      // canceled, or the spec's canceled-activation step restores checkedness.
      if (event.target !== input) event.preventDefault()
      input.checked = false
      this.wasChecked = false
      input.dispatchEvent(new Event("change", { bubbles: true }))
    } else {
      this.wasChecked = input.checked
    }
  }
}
