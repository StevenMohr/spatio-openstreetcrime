server_url = "http://localhost:8000"

$(document).ready ->
  GeoReceiver.init()
  $('button').click -> MapControls.toggle_district_layer()

DistrictMap =
  map: undefined
  district_layer: undefined

  initialize: () ->
    @.map = new OpenLayers.Map {div: 'map', projection: new OpenLayers.Projection 'EPSG:900313'}
    osm_layer = new OpenLayers.Layer.OSM()
    @.map.addLayer osm_layer

    @.add_district_layer()
    get_location()

  center_map: (center_x, center_y) ->
    @.map.setCenter((new OpenLayers.LonLat(center_x, center_y)).transform("EPSG:4326", "EPSG:900913"), 8)

  add_district_layer: () ->
    @.district_layer = new OpenLayers.Layer.Vector "Berlin Districts", {projection: new OpenLayers.Projection 'EPSG:900313'}
    @.district_layer.removeAllFeatures()
    @.district_layer.addFeatures(MapData.district_features())
    @.map.addLayer @.district_layer

MapData =
  map_data: []
  weighted: false
  district_features: ->
    relevant_count = (if (@.weighted) then 'weighted_count' else 'count')
    #in_options = {internalProjection: new OpenLayers.Projection('EPSG:4326'), externalProjection: new OpenLayers.Projection('EPSG:900913') }
    geojson_parser = new OpenLayers.Format.GeoJSON #in_options
    features = []

    for district in @map_data
      style = MapStyle.style(0) #@.district_color(district[0]))
      geojson_polygon = geojson_parser.read(district['area'])
      geojson_polygon.style = style
      features.push geojson_polygon
    features

  district_color: (count) ->
    colors =['#00ff00', '#ffff00', '#df7401', '#df0101']
    i = 0
    for quantil in @.quantils()
      if count < quantil
        break
      i++
    colors[i]

  quantils: ->
    if @.weighted
      return [5] #$('#map').data('quantils')['weighted']
    else
      return [5] #$('#map').data('quantils')['normal']

MapStyle =
  renderer: ->
    #renderer = OpenLayers.Util.getParameters(window.location.href).renderer
    renderer = OpenLayers.Layer.Vector::renderers

  layer_style: ->
    layer_style = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default'])
    layer_style.fillOpacity = 0.8
    layer_style.graphicOpacity = 1
    layer_style

  style: (color) ->
    style = OpenLayers.Util.extend({}, @.layer_style())
    style.strokeColor = 'red'
    style.fillColor = 'red'
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


get_location = () ->
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition show_position

show_position = (position) ->
  DistrictMap.center_map  position.coords.longitude, position.coords.latitude



GeoReceiver =
  init: () ->
    settings =
      dataType: 'jsonp'
      url: "#{server_url}/api/v1/communities/?state__name=Berlin"
      success: GeoReceiver.process_districts
    $.ajax settings

  process_districts: (data) =>
    MapData.map_data =  data['objects']
    DistrictMap.initialize()
