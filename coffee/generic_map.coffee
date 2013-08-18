configuration =
  server_url : "http://localhost:8000"   # Base URL to server
  rest_resource : "api/v1/reports/"      # URL of REST ressource to visualize
  geo_attribute_name : "location"        # Attribute of REST ressource containing geo information to visualize as GeoJSON
  object_color : '#00ff00'               # Color to use to render objects
  container_attribute_name :"objects"    # Name of the attribute in top-level JSON that contains all objects to visualize
  center_x : 0                           # X coordinate used to center map
  center_y : 0                           # Y coordinate used to center map

epsg4326 = new OpenLayers.Projection('EPSG:4326')
epsg900913 = new OpenLayers.Projection('EPSG:900913')



DistrictMap =
  map: null
  data_layer: null

  initialize: () ->
    @map = new OpenLayers.Map('map', projection: epsg900913, displayProjection: epsg4326)
    layer = new OpenLayers.Layer.OSM()
    @map.addLayer layer
    @add_data_layer()
    @center_map(configuration.center_x, configuration.center_y)

  center_map: (center_x, center_y) ->
    @map.setCenter((new OpenLayers.LonLat(center_x, center_y)).transform("EPSG:4326", "EPSG:900913"), 8)

  add_data_layer: () ->
    @data_layer = new OpenLayers.Layer.Vector "Map Data"
    @data_layer.removeAllFeatures()
    features = MapData.data_feature_collection()
    @data_layer.addFeatures features
    @map.addLayer @data_layer


MapData =
  map_data: []

  data_feature_collection: ->
    featurecollection = []
    geojson_format = new OpenLayers.Format.GeoJSON()
    for district in @map_data
      feature = {"geometry": null, "type": "Feature", "properties": {}}
      style = MapStyle.style(configuration.object_color)
      feature.geometry = district[configuration.geo_attribute_name]
      feature = geojson_format.parseFeature feature
      feature.style = style
      featurecollection.push feature
    featurecollection


MapStyle =
  renderer: ->
    renderer = OpenLayers.Layer.Vector::renderers

  layer_style: ->
    layer_style = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default'])
    layer_style.fillOpacity = 0.3
    layer_style.graphicOpacity = 1
    layer_style

  style: (color) ->
    style = OpenLayers.Util.extend({}, @layer_style())
    style.strokeColor = color
    style.fillColor = color
    style


GeoReceiver =
  init: () ->
    settings =
      dataType: 'jsonp'
      url: "#{configuration.server_url}/#{configuration.rest_resource}"
      success: GeoReceiver.process_data
    $.ajax settings

  process_data: (data) =>
    MapData.map_data = MapData.map_data.concat data[container_attribute_name]
    if data.meta.next?
      settings =
      dataType: 'jsonp'
      url: configuration.server_url + data.meta.next
      success: GeoReceiver.process_data
      $.ajax settings
    else
      DistrictMap.initialize()


jQuery ->
  GeoReceiver.init()
