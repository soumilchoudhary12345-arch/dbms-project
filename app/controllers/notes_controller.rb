class NotesController < ApplicationController
  def index
    @subjects = ContentLibrary.subjects(root: StudyContent.notes_root)
  end

  def show
    @subject = ContentLibrary.find_subject(params[:subject], root: StudyContent.notes_root)
    render_not_found unless @subject
    @chapter_count = ContentLibrary.max_chapter_number
  end

  private

  def render_not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
