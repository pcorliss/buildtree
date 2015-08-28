module BuildsHelper
  include FontAwesome::Rails::IconHelper

  def build_status(status)
    case status
    when 'pending'
      link_to '#', data: {toggle: 'tooltip', 'original-title': 'in progress', placement: 'right'} do
        fa_icon "cog spin fw"
      end
    when 'queued'
      link_to '#', data: {toggle: 'tooltip', 'original-title': 'queued', placement: 'right'} do
        fa_icon "clock-o fw"
      end
    when 'success'
      link_to '#', data: {toggle: 'tooltip', 'original-title': 'success', placement: 'right'} do
        fa_icon "check fw", class: 'text-success'
      end
    when 'failure'
      link_to '#', data: {toggle: 'tooltip', 'original-title': 'failure', placement: 'right'} do
        fa_icon "times fw", class: 'text-danger'
      end
    else
      link_to '#', data: {toggle: 'tooltip', 'original-title': 'error', placement: 'right'} do
        fa_icon "exclamation-triangle fw", class: 'text-danger'
      end
    end
  end
end
