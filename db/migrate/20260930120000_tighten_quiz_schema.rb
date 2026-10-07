class TightenQuizSchema < ActiveRecord::Migration[8.1]
  def up
    # 1. Normalise existing rows so the new constraints hold for every record.
    #    (backups of storage/*.sqlite3 live in db/backups/20260930_pre_schema_tighten/)
    execute "UPDATE users SET email = lower(trim(email)) WHERE email IS NOT NULL"
    execute <<~SQL
      UPDATE quiz_sessions
         SET status = CASE status
                        WHEN 'active'   THEN 'in_progress'
                        WHEN 'finished' THEN 'submitted'
                        ELSE status
                      END
    SQL
    execute "UPDATE questions SET difficulty = 'hard' WHERE difficulty = 'super_hard'"
    execute "UPDATE questions SET q_type = 'mcq' WHERE q_type = 'assertion_reason'"

    # 2. New columns.
    add_column :question_attempts, :time_taken_seconds, :integer
    add_column :quiz_sessions, :total_questions, :integer, null: false, default: 0
    execute <<~SQL
      UPDATE quiz_sessions
         SET total_questions = (SELECT count(*)
                                  FROM question_attempts qa
                                 WHERE qa.quiz_session_id = quiz_sessions.id)
    SQL

    # 3. QUESTIONS.options: text -> JSON (values are already valid JSON).
    change_column :questions, :options, :json

    # 4. Indexes: unique email, unique attempt per session+question, topic/difficulty.
    add_index :users, :email, unique: true, name: "index_users_on_email"
    add_index :question_attempts, [ :quiz_session_id, :question_id ],
              unique: true, name: "index_question_attempts_on_session_and_question"
    add_index :questions, [ :topic, :difficulty ], name: "index_questions_on_topic_and_difficulty"

    # 5. CHECK constraints.
    add_check_constraint :quiz_sessions, "status IN ('in_progress', 'submitted')",
                         name: "chk_quiz_sessions_status"
    add_check_constraint :questions, "difficulty IN ('easy', 'medium', 'hard')",
                         name: "chk_questions_difficulty"
    add_check_constraint :questions, "q_type IN ('mcq', 'short', 'long')",
                         name: "chk_questions_q_type"
    add_check_constraint :questions, "marks > 0", name: "chk_questions_marks_positive"
  end

  def down
    remove_check_constraint :questions, name: "chk_questions_marks_positive"
    remove_check_constraint :questions, name: "chk_questions_q_type"
    remove_check_constraint :questions, name: "chk_questions_difficulty"
    remove_check_constraint :quiz_sessions, name: "chk_quiz_sessions_status"

    remove_index :questions, name: "index_questions_on_topic_and_difficulty"
    remove_index :question_attempts, name: "index_question_attempts_on_session_and_question"
    remove_index :users, name: "index_users_on_email"

    change_column :questions, :options, :text

    remove_column :quiz_sessions, :total_questions
    remove_column :question_attempts, :time_taken_seconds

    execute <<~SQL
      UPDATE quiz_sessions
         SET status = CASE status
                        WHEN 'in_progress' THEN 'active'
                        WHEN 'submitted'    THEN 'finished'
                        ELSE status
                      END
    SQL
    # Not reversible (by design, and loss-free in production data):
    #   - difficulty 'super_hard' -> 'hard'   (0 rows existed)
    #   - q_type 'assertion_reason' -> 'mcq'  (chosen over keeping the value)
  end
end
