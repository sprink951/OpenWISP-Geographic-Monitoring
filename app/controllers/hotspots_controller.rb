class HotspotsController < ApplicationController
  before_filter :authenticate_user!, :unless => :georss?
  before_filter :load_wisp

  access_control do
    default :deny

    actions :index, :show do
      allow :wisps_viewer
      allow :wisp_hotspots_viewer, :of => :wisp, :if => :wisp_loaded?
    end

    allow all, :to => :index, :if => :georss?
  end

  def index
    respond_to do |format|
      format.any(:html, :js) { @hotspots = hotspots_with_sort_seach_and_paginate.of_wisp(@wisp) }
      format.json { @hotspots = hotspots_with_filter.of_wisp(@wisp).draw_map }
      format.rss { @hotspots = Hotspot.on_georss }
    end

    crumb_for_wisp
  end

  def show
    @hotspot = Hotspot.find params[:id]

    crumb_for_wisp
    crumb_for_hotspot
  end

  private

  def hotspots_with_filter
    case params[:filter]
      when 'up'
        Hotspot.up
      when 'down'
        Hotspot.down
      when 'unknown'
        Hotspot.unknown
      else
        Hotspot
    end
  end

  def hotspots_with_sort_seach_and_paginate
    query = params[:q] || nil
    column = params[:column] ? params[:column].downcase : nil
    direction = %w{asc desc}.include?(params[:order]) ? params[:order] : 'asc'

    hotspots = Hotspot.scoped
    hotspots = hotspots.sort_with(t_column(column), direction) if column
    hotspots = hotspots.hostname_like(query) if query

    hotspots.page params[:page]
  end

  def t_column(column)
    i18n_columns = {}
    i18n_columns[I18n.t(:status, :scope => [:activerecord, :attributes, :hotspot])] = 'status'

    Hotspot.column_names.each do |col|
      i18n_columns[I18n.t(col, :scope => [:activerecord, :attributes, :hotspot])] = col
    end

    i18n_columns.include?(column) ? i18n_columns[column] : 'hostname'
  end

  def georss?
    request.format.rss?
  end

  def crumb_for_wisp
    begin
      add_breadcrumb I18n.t(:Hotspots_for, :wisp => @wisp.name), wisp_hotspots_path(@wisp)
    rescue
      add_breadcrumb I18n.t(:Hotspots_of_every_wisp), hotspots_path
    end
  end

  def crumb_for_hotspot
    add_breadcrumb I18n.t(:Hotspot_named, :hostname => @hotspot.hostname), wisp_hotspot_path(@hotspot.wisp, @hotspot)
  end
end
