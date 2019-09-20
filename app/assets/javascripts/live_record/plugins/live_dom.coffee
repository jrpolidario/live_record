#= require_self
#= require_directory ./live_dom/

this.LiveRecord.plugins.LiveDOM ||= {}

if window.jQuery == undefined
  throw new Error('jQuery is not loaded yet, and is a dependency of LiveDOM plugin')
