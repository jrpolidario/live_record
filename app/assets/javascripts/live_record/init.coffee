#= require_self

# cable is an ActionCable consumer
this.LiveRecord.init ||= (cable) ->
  this.cable = cable
