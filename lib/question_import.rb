require "json"

module QuestionImport
  module_function

  ASSERTION_REASON_OPTIONS = {
    "A" => "Both (A) and (R) are true and (R) is the correct explanation of (A).",
    "B" => "Both (A) and (R) are true but (R) is not the correct explanation of (A).",
    "C" => "(A) is true but (R) is false.",
    "D" => "(A) is false but (R) is true."
  }.freeze

  # pdftotext emits Private Use Area codepoints for glyphs whose fonts have no
  # ToUnicode map (Symbol/MT-Extra math glyphs). Each codepoint below was
  # decoded by reading every context it appears in; unknown codepoints drop.
  PUA_MAP = {
    0xF022 => "∀", 0xF024 => "\u0302", 0xF028 => "(", 0xF029 => ")",
    0xF02B => "+", 0xF02D => "-", 0xF03C => "<", 0xF03D => "=", 0xF03E => ">",
    0xF051 => ",", 0xF05B => "[", 0xF05C => "∴", 0xF05D => "]",
    0xF06C => "λ", 0xF06D => "μ", 0xF070 => ".", 0xF072 => "", 0xF075 => "",
    0xF07B => "{", 0xF07D => "}",
    0xF0A1 => "ℝ", 0xF0A3 => "≤", 0xF0A5 => "∞", 0xF0AE => "→",
    0xF0B1 => "±", 0xF0B3 => "≥", 0xF0B4 => "×",
    0xF0C7 => "∩", 0xF0C8 => "∪", 0xF0CE => "∈", 0xF0DE => "⇒",
    0xF0E6 => "(", 0xF0E7 => "(", 0xF0E8 => "(", 0xF0E9 => "[",
    0xF0EA => "[", 0xF0EB => "[", 0xF0EC => "{", 0xF0ED => "{",
    0xF0EE => "≠", 0xF0EF => "",
    0xF0F2 => "∫", 0xF0F6 => "(", 0xF0F7 => "(", 0xF0F8 => ")",
    0xF0F9 => "]", 0xF0FA => "]", 0xF0FB => "]"
  }.freeze

  def decode_glyphs(text)
    s = text.to_s.gsub(/[-]/) { |c| PUA_MAP[c.ord] || "" }
    s = s.gsub(/\[\[+/, "[").gsub(/\]\]+/, "]").gsub(/\{\{+/, "{")
    s = s.gsub(/(\u0302+)(\S)/, "\\2\\1") # hat drawn before its letter -> after
    s.gsub(/\s*---\s*/, " ").unicode_normalize(:nfkc)
  end

  def sanitize(text)
    decode_glyphs(text).gsub(/\bpage \d+ of \d+\b/, "")
                       .gsub(/\s+/, " ").strip
                       .sub(/\A[.:–-]+\s*/, "")
  end

  def sanitize_body(text)
    decode_glyphs(text).gsub(/\bpage \d+ of \d+\b/, "")
                       .split("\n").map { |l| l.gsub(/\s+/, " ").strip }
                       .reject(&:empty?).join("\n")
                       .sub(/\A[.:–-]+\s*/, "")
  end

  def run(repo_path)
    repo = Pathname.new(repo_path || "/tmp/cbse_repo")
    sqp_root = repo.join("corpus/markdown_sqp_archive/SQP")
    abort("Repo not found at #{repo}") unless sqp_root.directory?

    imported = 0
    skipped = 0

    sqp_root.children.select(&:directory?).sort.each do |session_dir|
      sqp_file = session_dir.join("Maths-SQP.md")
      ms_file  = session_dir.join("Maths-MS.md")
      next unless sqp_file.file? && ms_file.file?

      session = session_dir.basename.to_s
      answers = parse_answers(ms_file.read)
      questions = parse_questions(sqp_file.read)

      (questions.keys & answers.keys).sort.each do |q_no|
        q = questions[q_no]
        answer = answers[q_no]
        if q_no >= 19 && (q[:options].nil? || q[:options].size < 4)
          q[:options] = ASSERTION_REASON_OPTIONS
        end
        if q[:options].nil? || q[:options].size < 4 || q[:body].blank? || answer.nil?
          skipped += 1
          next
        end

        label = source_label(session)
        key = sanitize(q[:body])
        record = Question.where(subject: "Mathematics", source: label)
                         .find { |r| sanitize(r.body) == key }
        record ||= Question.new(subject: "Mathematics", source: label)
        body = sanitize_body(q[:body])
        record.body = body if record.body != body
        record.q_type     = "mcq"
        record.marks      = 1
        record.difficulty = q_no >= 19 ? "hard" : "medium"
        record.options    = q[:options]
        record.answer     = answer[:letter]
        record.solution   = sanitize(answer[:solution]).presence
        record.save!
        imported += 1
      end
    end

    puts "Imported rows: #{imported} (skipped incomplete: #{skipped})"
    puts "Questions in DB: #{Question.count}"
    puts "With answers: #{Question.where.not(answer: [ nil, "" ]).count}"
  end

  def source_label(session)
    "CBSE SQP #{session.sub('Class', '').tr('_', '-')}"
  end

  def parse_answers(text)
    answers = {}
    current = nil
    text.each_line do |line|
      if (m = line.match(/^\s*(\d{1,2})\s*[.)]?\s*\(([A-Da-d])\)\s*(.*)$/))
        current = m[1].to_i
        answers[current] = { letter: m[2].upcase, solution: m[3].to_s.strip }
      elsif current && answers[current] && line =~ /^\s{4,}\S/
        answers[current][:solution] += " #{line.strip}"
      elsif line =~ /^\s*\d{1,2}\s*[.)]/
        current = nil
      end
    end
    answers.transform_values do |a|
      sol = a[:solution].to_s.gsub(/\s+/, " ").strip
      { letter: a[:letter], solution: sol.first(600) }
    end
  end

  def parse_questions(text)
    body = text.dup
    body.sub!(/\A---.*?---/m, "")
    body.gsub!(/^```.*?$/, "")
    body.gsub!(/^## page \d+$/, "")
    body.gsub!(/^.*Class-XII\/Sample Paper\/.*$/, "")
    body.gsub!(/^\s*Select the correct option.*$/, "")

    questions = {}
    body.split(/(?=Q\.?\d+\.)/).each do |part|
      m = part.match(/\AQ\.?(\d+)\./)
      next unless m

      q_no = m[1].to_i
      next if q_no > 20

      markers = part.to_enum(:scan, /\(([A-Da-d])\)/)
                    .map { [ Regexp.last_match.begin(0), Regexp.last_match[1].upcase ] }
      markers = dedupe_letters(markers)
      if markers.size < 4
        questions[q_no] = { body: sanitize_body(cut_section(part.sub(/\AQ\.?\d+\./, ""))), options: nil }
        next
      end

      stem = cut_section(part[0...markers.first[0]].sub(/\AQ\.?\d+\./, ""))
      questions[q_no] = { body: sanitize_body(stem), options: extract_options(part, markers) }
    end
    questions
  end

  def cut_section(text)
    text.split(/\bSECTION-?[A-E]\b|\bSection\s*[–-]\s*[A-E]\b/).first || text
  end

  def dedupe_letters(markers)
    seen = {}
    markers.select do |_pos, letter|
      first = !seen[letter]
      seen[letter] = true
      first
    end
  end

  def extract_options(block, markers)
    options = {}
    markers.first(4).each_with_index do |(pos, letter), i|
      finish = i + 1 < 4 ? markers[i + 1][0] : block.length
      raw = block[(pos + 3)...finish]
      raw = raw.split(/Both \(A\) and \(R\)|ASSERTION \(A\)|Assertion \(A\)/).first || raw
      options[letter] = clean_text(cut_section(raw))
    end
    options.size == 4 ? options : nil
  end

  def clean_text(text)
    sanitize(text.to_s)
  end
end
