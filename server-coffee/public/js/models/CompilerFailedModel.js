var CompilerFailed = Backbone.Model.extend({
	initialize: function(data) {
		if (_.isString(data.message)) {
			console.log(data);
			this.message = $.trim(data.message);
		} else {
			this.message = 'Failed to compile input program';
		}
		this.stderr = $.trim(data.stderr);
		this.stdout = $.trim(data.stdout);
	},
	defaults: function() {
		return {
			message: 'Failed to compile input program',
			stderr: null,
			stdout: null
		};
	}
});
