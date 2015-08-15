module BuildsHelper
  include FontAwesome::Rails::IconHelper

  def build_status(status)
    case status
    when 'pending'
      fa_icon "cog spin fw"
    when 'queued'
      fa_icon "clock-o fw"
    when 'success'
      fa_icon "check fw", class: 'text-success'
    when 'failure'
      fa_icon "times fw", class: 'text-danger'
    else
      fa_icon "exclamation-triangle fw", class: 'text-danger'
    end
  end
end
