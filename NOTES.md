# TODO

+ Display a dashboard index if no default dashboard is specified.
+ Add a container class, for better layout. Get rid of masonry.
+ Fix up 'scroll' tile.
+ Create a 'delta' tile. (Up / down X percent.)
+ Support user-defined plugins.
+ Automatically support librato style log statements, ie:
  "count#user.clicks=1" - count metric type.
  "sample#database.size=40.9MB" - gauge metric type.
  "measure#database.query=200ms" - append metric type, support stats on browser side.
