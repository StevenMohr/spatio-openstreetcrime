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
    geojson_format = new OpenLayers.Format.GeoJSON()
    @.district_layer = new OpenLayers.Layer.Vector "Berlin Districts"
    @.district_layer.removeAllFeatures()
    features = geojson_format.read(MapData.district_feature_collection())
    @.district_layer.addFeatures features
    @.map.addLayer @.district_layer

MapData =
  map_data: []
  weighted: false
  district_feature_collection: ->
    featurecollection = {"type": "FeatureCollection", "features": [{"geometry": { "type": "GeometryCollection", "geometries": []}, "type": "Feature", "properties": {}}]}
    for district in @map_data
      district_feature = district['area']
      featurecollection.features[0].geometry.geometries.push district_feature
    featurecollection

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
