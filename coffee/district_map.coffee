server_url = "http://localhost:8000"

$(document).ready ->
  GeoReceiver.init()
  $('button').click -> MapControls.toggle_district_layer()

DistrictMap =
  map: undefined
  district_layer: undefined

  initialize: () ->
    epsg4326 = new OpenLayers.Projection('EPSG:4326')
    epsg900913 = new OpenLayers.Projection('EPSG:900913')

    @.map = new OpenLayers.Map('map', projection: epsg900913, displayProjection: epsg4326)
    layer = new OpenLayers.Layer.OSM()
    @.map.addLayer layer
    @.map.setCenter(new OpenLayers.LonLat(13, 52).transform(epsg4326, epsg900913), 8)

    vector_layer = new OpenLayers.Layer.Vector "Berlin Districts"
    @.add_district_layer()

  center_map: (center_x, center_y) ->
    @.map.setCenter((new OpenLayers.LonLat(center_x, center_y)).transform("EPSG:4326", "EPSG:900913"), 8)

  add_district_layer: () ->

    @.district_layer = new OpenLayers.Layer.Vector "Berlin Districts"
    @.district_layer.removeAllFeatures()
    features = MapData.district_feature_collection()
    @.district_layer.addFeatures features
    @.map.addLayer @.district_layer

MapData =
  map_data: []
  weighted: false
  district_feature_collection: ->
    featurecollection = []
    geojson_format = new OpenLayers.Format.GeoJSON()
    for district in @map_data
      feature = {"geometry": null, "type": "Feature", "properties": {}}
      style = MapStyle.style(@.district_color(ReportReceiver.crime_stat[district.resource_uri]))
      feature.geometry = district['area']
      feature = geojson_format.parseFeature feature
      feature.style = style
      featurecollection.push feature
    featurecollection

  district_color: (count) ->
    colors =['#00ff00', '#ffff00', '#df7401', "#ff0000" ]
    if not count?
      count = 0
    i = 0
    for quantil in @.quantils()
      if count < quantil
        break
      i++
    colors[i]

  quantils: ->
    if @.weighted
      return [1,3,5] #$('#map').data('quantils')['weighted']
    else
      return [1,3,5] #$('#map').data('quantils')['normal']

MapStyle =
  renderer: ->
    #renderer = OpenLayers.Util.getParameters(window.location.href).renderer
    renderer = OpenLayers.Layer.Vector::renderers

  layer_style: ->
    layer_style = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default'])
    layer_style.fillOpacity = 0.3
    layer_style.graphicOpacity = 1
    layer_style

  style: (color) ->
    style = OpenLayers.Util.extend({}, @.layer_style())
    style.strokeColor = color
    style.fillColor = color
    style

MapControls =
  toggle_district_layer: ->
    button = $('#button')
    if button.text() == "Change to Weighted"
      MapData.weighted = true
      button.text('Change to Normal')
    else
      MapData.weighted = false
      button.text('Change to Weighted')
    DistrictMap.add_district_layer()

  update_legend: ->
    i = 0
    quantils = MapData.quantils()
    for quantil in quantils
      $("#quantil#{i}").text("less than #{quantil}")
      i++
    $("#quantil3").text("greater than or equal to #{quantils[2]}")

GeoReceiver =
  init: () ->
    settings =
      dataType: 'jsonp'
      url: "#{server_url}/api/v1/districts/?community__state__name=Berlin"
      success: GeoReceiver.process_districts
    $.ajax settings

  process_districts: (data) =>
    MapData.map_data = MapData.map_data.concat data['objects']
    if data.meta.next?
      settings =
      dataType: 'jsonp'
      url: server_url + data.meta.next
      success: GeoReceiver.process_districts
      $.ajax settings
    else
      ReportReceiver.init()

ReportReceiver =
  berlin_bbox : null
  reports: []
  crime_stat : {}
  init: () ->
    settings =
      dataType: 'jsonp'
      url: "#{server_url}/api/v1/states/?name=Berlin"
      success: ReportReceiver.process_state
    $.ajax settings

  process_state: (data) =>
    @berlin_bbox = data.objects[0].bbox
    settings =
      dataType: 'jsonp'
      url: "#{server_url}/api/v1/reports/?location__within=" + JSON.stringify(@berlin_bbox)
      success: ReportReceiver.get_reports
    $.ajax settings

  get_reports: (data) ->
    ReportReceiver.reports = ReportReceiver.reports.concat data.objects
    if data.meta.next?
      settings =
      dataType: 'jsonp'
      url: server_url + data.meta.next
      success: ReportReceiver.get_reports
      $.ajax settings
    else
      ReportReceiver.process_reports()

  process_reports: () =>
    settings =
      dataType: 'jsonp'
      success: ReportReceiver.update_crime_stat
    ReportReceiver.open_report_requests = ReportReceiver.reports.length
    for report in ReportReceiver.reports
      settings.url = "#{server_url}/api/v1/districts/?area__contains=" + JSON.stringify(report.location)
      $.ajax settings

  update_crime_stat: (data) =>
    if not ReportReceiver.crime_stat[data.objects[0].resource_uri]?
      ReportReceiver.crime_stat[data.objects[0].resource_uri] = 1
    else
      ReportReceiver.crime_stat[data.objects[0].resource_uri] += 1
    ReportReceiver.open_report_requests -= 1
    if ReportReceiver.open_report_requests <= 0
      DistrictMap.initialize()
