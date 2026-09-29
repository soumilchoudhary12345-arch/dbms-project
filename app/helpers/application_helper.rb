module ApplicationHelper
  def nav_class(active)
    class_names("rounded-md px-3 py-2 text-sm font-medium hover:bg-slate-100",
                "bg-indigo-50 text-indigo-700": active)
  end
end
