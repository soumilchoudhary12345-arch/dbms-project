require_relative "../question_import"

namespace :questions do
  desc "Import CBSE Class XII Maths SQP MCQs with answers from a local clone of CBSE_paper_patterns"
  task :import, [ :repo_path ] => :environment do |_t, args|
    QuestionImport.run(args[:repo_path])
  end
end
