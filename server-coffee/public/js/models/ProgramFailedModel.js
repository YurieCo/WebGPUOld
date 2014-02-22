var ProgramFailed = Backbone.Model.extend({
	initialize: function(data) {
		this.message = $.trim(data.message);
		this.stderr = $.trim(data.stderr);
		this.stdout = $.trim(data.stdout);
	},
	defaults: function() {
		return {
			message: 'Failed to run input program',
			stderr: null,
			stdout: null
		};
	}
});
