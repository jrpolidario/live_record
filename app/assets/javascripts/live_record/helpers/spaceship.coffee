# ref: https://stackoverflow.com/questions/34852855/combined-comparison-spaceship-operator-in-javascript

LiveRecord.helpers.spaceship = (val1, val2) ->
  if val1 == null or val2 == null or typeof val1 != typeof val2
    return null
  if typeof val1 == 'string'
    val1.localeCompare val2
  else
    if val1 > val2
      return 1
    else if val1 < val2
      return -1
    0
