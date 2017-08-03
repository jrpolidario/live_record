LiveRecord.helpers.loadRecords = (args) ->
  args['modelName'] || throw new Error(':modelName argument required')
  throw new Error(':modelName is not defined in LiveRecord.Model.all') if LiveRecord.Model.all[args['modelName']] == undefined

  args['url'] ||= window.location.href

  $.getJSON(
    args['url']
  ).done(
    (data) -> 
      # Array JSON
      if $.isArray(data)
        records_attributes = data;
        records = []

        for record_attributes in records_attributes
          record = new LiveRecord.Model.all[args['modelName']](record_attributes);
          record.create();
          records << record

      # Single-Record JSON
      else
        record_attributes = data
        record = new LiveRecord.Model.all[args['modelName']](record_attributes);
        record.create();

      args['onLoad'].call(this, records) if args['onLoad']
  ).fail(
    (jqxhr, textStatus, error) ->
      args['onError'].call(this, jqxhr, textStatus, error) if args['onError']
  )