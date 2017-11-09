# ref: https://jamesroberts.name/blog/2010/02/22/string-functions-for-javascript-trim-to-camel-case-to-dashed-and-to-underscore/

LiveRecord.helpers.caseConverter =
  toCamel: (string) ->
    string.replace(
      /(\-[a-z])/g,
      ($1) ->
        $1.toUpperCase().replace('-','')
    )

  toUnderscore: (string) ->
	  string.replace(
      /([A-Z])/g,
      ($1) ->
        "_"+$1.toLowerCase()
    )
