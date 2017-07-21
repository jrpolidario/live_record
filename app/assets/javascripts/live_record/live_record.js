//= require_self
//= require_directory ./live_record/

this.LiveRecord || (this.LiveRecord = {});

if (window.jQuery === undefined) {
	 throw new Error('jQuery is not loaded yet, and is a dependency of LiveRecord')
}