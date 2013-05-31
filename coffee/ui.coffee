init_heat_map = () ->
  OsmHeatMap.initialize()

init_history_map = () ->
  HistoryMap.initialize()

$('#heat_link').click () ->
  setTimeout(init_heat_map, 100)

$('#history_link').click () ->
  setTimeout(init_history_map, 100)