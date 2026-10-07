module ApplicationHelper
  # Pretty names for question topics (data/questions.json "topic" column).
  TOPIC_NAMES = {
    "relations/functions" => "Relations & Functions",
    "matrices"            => "Matrices",
    "determinants"        => "Determinants",
    "calculus"            => "Calculus",
    "vectors"             => "Vector Algebra",
    "3d geometry"         => "Three Dimensional Geometry",
    "probability"         => "Probability"
  }.freeze

  NAV_ICONS = {
    notes:    '<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4"/><path d="M10 12h5"/><path d="M10 16h5"/>',
    book:     '<path d="M12 6.5C10 4.8 7.2 4.2 4 4.5v13c3.2-.3 6 .3 8 2 2-1.7 4.8-2.3 8-2v-13c-3.2-.3-6 .3-8 2z"/><path d="M12 6.5v12"/>',
    questions: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3.2"/>',
    mistakes: '<circle cx="12" cy="12" r="9"/><path d="m9.5 9.5 5 5m0-5-5 5"/>',
    themes:   '<circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 1 0 16z" fill="currentColor" stroke="none"/>',
    signout:  '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
    chevron:  '<path d="m14 6-6 6 6 6"/>'
  }.freeze

  # Palette presets shown on the Themes page (single source of truth).
  def theme_presets
    [
      [ "light",     "Light",    "Graph paper, fountain-pen blue",      [ "#fbfcfd", "#2f4bc4", "#171a21" ] ],
      [ "sunset",    "Sunset",   "Peach dusk paper, ember orange",     [ "#fdf6ef", "#d95f26", "#2a1a10" ] ],
      [ "focus",     "Focus",    "Warm ruled paper, olive ink",        [ "#f4f1e6", "#5f6b3c", "#2c2920" ] ],
      [ "vibrant",   "Vibrant",  "Rose paper, rose accent",            [ "#fff5f7", "#e11d48", "#20131a" ] ],
      [ "dark",      "Dark",     "Green chalkboard, periwinkle chalk", [ "#0e2a1e", "#5666da", "#e7efe9" ] ],
      [ "blueprint", "Blueprint", "Drafting blue, white grid, cyan ink", [ "#0b2e52", "#5fb8f0", "#e9f3fc" ] ],
      [ "terminal",  "Terminal", "CRT scanlines, terminal green, mono", [ "#0b1220", "#35d07f", "#d8e4f5" ] ],
      [ "solar",     "Solar",    "Solarized deep teal, hacker classic", [ "#002b36", "#2aa198", "#e9e4d0" ] ],
      [ "atelier",   "Atelier",  "Matte black, gold leaf, big serif",   [ "#0c0b0a", "#d4a53d", "#f2efe8" ] ],
      [ "noir",      "Noir",     "Cinema black, silver white, no grid", [ "#0a0a0a", "#ffffff", "#a3a3a3" ] ]
    ]
  end

  def nav_icon(name)
    content_tag(:svg, NAV_ICONS.fetch(name).html_safe,
                viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
                "stroke-width": 1.75, "stroke-linecap": "round", "stroke-linejoin": "round",
                class: "nav-icon h-5 w-5 shrink-0", aria_hidden: true)
  end

  def nav_class(active)
    class_names("nav-link flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium hover:bg-slate-100",
                "bg-indigo-50 text-indigo-700": active)
  end

  def topic_name(topic)
    key = topic.to_s.downcase
    TOPIC_NAMES[key] || topic.to_s.humanize
  end

  def chapter_title(number)
    ContentLibrary.title_for(number)
  end
end
