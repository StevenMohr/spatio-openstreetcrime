init_heat_map = () ->
  OsmHeatMap.initialize()

$('#heat_link').click () ->
  setTimeout(init_heat_map, 100)