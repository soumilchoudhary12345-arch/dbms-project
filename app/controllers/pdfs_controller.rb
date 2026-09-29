class PdfsController < ApplicationController
  def show
    root = params[:kind] == "notes" ? StudyContent.notes_root : StudyContent.root
    chapter = ContentLibrary.find_chapter(params[:subject], params[:number], params[:part], root: root)

    unless chapter && chapter.path.exist?
      render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
      return
    end

    disposition = params[:download].present? ? :attachment : :inline
    send_file chapter.path,
              type: "application/pdf",
              disposition: disposition,
              filename: chapter.filename
  end
end
