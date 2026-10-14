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

  # Grouped collections for clean, simplified theme selection with customizable color bindings.
  def theme_collections
    [
      {
        id: "paper",
        name: "Paper & Ink",
        tagline: "Natural study stationery, warm notebook surfaces, and tactile inks.",
        icon: '<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z"/><path d="M6 6h10"/><path d="M6 10h10"/>',
        variants: [
          { id: "light",   name: "Graph Blue", desc: "Crisp graph paper & fountain-pen cobalt", chips: [ "#fbfcfd", "#2f4bc4", "#171a21" ] },
          { id: "focus",   name: "Olive Ruled", desc: "Warm ruled paper & vintage olive ink",   chips: [ "#f4f1e6", "#5f6b3c", "#2c2920" ] },
          { id: "sunset",  name: "Peach Ember", desc: "Soft dusk paper & warm ember orange",   chips: [ "#fdf6ef", "#d95f26", "#2a1a10" ] },
          { id: "vibrant", name: "Rose Quartz", desc: "Rose-tinted parchment & vivid crimson", chips: [ "#fff5f7", "#e11d48", "#20131a" ] }
        ]
      },
      {
        id: "chalk",
        name: "Studio & Academy",
        tagline: "Classroom chalkboard and architectural blueprint drafting desks.",
        icon: '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="m9 9 6 6m0-6-6 6"/>',
        variants: [
          { id: "dark",      name: "Chalkboard", desc: "Green slate chalkboard & periwinkle chalk", chips: [ "#0e2a1e", "#5666da", "#e7efe9" ] },
          { id: "blueprint", name: "Cyan Blueprint", desc: "Technical drafting grid & cyan ink",    chips: [ "#0b2e52", "#5fb8f0", "#e9f3fc" ] }
        ]
      },
      {
        id: "digital",
        name: "Cyber & Terminal",
        tagline: "Retro cathode-ray glow and hacker solarized teal workstations.",
        icon: '<polyline points="4 17 10 11 4 5"/><line x1="12" x2="20" y1="19" y2="19"/>',
        variants: [
          { id: "terminal", name: "CRT Green", desc: "Phosphor scanlines & monospace terminal green", chips: [ "#0b1220", "#35d07f", "#d8e4f5" ] },
          { id: "solar",    name: "Solarized", desc: "Deep cyan-teal backdrop & warm teal accent",      chips: [ "#002b36", "#2aa198", "#e9e4d0" ] }
        ]
      },
      {
        id: "monochrome",
        name: "Cinema & Atelier",
        tagline: "Minimalist black canvas, gold leaf foil, and silver cinema frames.",
        icon: '<circle cx="12" cy="12" r="10"/><path d="M12 2a7 7 0 1 0 10 10"/>',
        variants: [
          { id: "atelier", name: "Gold Leaf", desc: "Matte black canvas, gilded gold & serif type", chips: [ "#0c0b0a", "#d4a53d", "#f2efe8" ] },
          { id: "noir",    name: "Pure Noir", desc: "Silver monochrome typography & cinema black",   chips: [ "#0a0a0a", "#ffffff", "#a3a3a3" ] }
        ]
      }
    ]
  end

  # Flattened palette presets (kept for backward compatibility and quick lookups).
  def theme_presets
    theme_collections.flat_map do |col|
      col[:variants].map { |v| [v[:id], v[:name], v[:desc], v[:chips]] }
    end
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
