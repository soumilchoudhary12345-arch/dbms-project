require "json"

module QuestionImport
  module_function

  ASSERTION_REASON_OPTIONS = {
    "A" => "Both (A) and (R) are true and (R) is the correct explanation of (A).",
    "B" => "Both (A) and (R) are true but (R) is not the correct explanation of (A).",
    "C" => "(A) is true but (R) is false.",
    "D" => "(A) is false but (R) is true."
  }.freeze

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

        record = Question.find_or_initialize_by(
          subject: "Mathematics",
          source: source_label(session),
          body: q[:body]
        )
        record.q_type     = q_no >= 19 ? "assertion_reason" : "mcq"
        record.marks      = 1
        record.difficulty = q_no >= 19 ? "hard" : "medium"
        record.options    = JSON.generate(q[:options])
        record.answer     = answer[:letter]
        record.solution   = answer[:solution].presence
        record.save!
        imported += 1
      end
    end

    puts "Imported rows: #{imported} (skipped incomplete: #{skipped})"
    puts "Questions in DB: #{Question.count}"
    puts "With answers: #{Question.where.not(answer: [nil, ""]).count}"
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
                    .map { [Regexp.last_match.begin(0), Regexp.last_match[1].upcase] }
      markers = dedupe_letters(markers)
      if markers.size < 4
        questions[q_no] = { body: clean_text(cut_section(part.sub(/\AQ\.?\d+\./, ""))), options: nil }
        next
      end

      stem = cut_section(part[0...markers.first[0]].sub(/\AQ\.?\d+\./, ""))
      questions[q_no] = { body: clean_text(stem), options: extract_options(part, markers) }
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
    text.to_s.gsub(/\s+/, " ").strip.sub(/\A[.:–-]+\s*/, "")
  end
end
