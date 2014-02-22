var SubmissionFailed = Backbone.Model.extend({
	initialize: function(data) {
		this.message = $.trim(data.message);
	},
	defaults: function() {
		return {
			message: 'Failed to submit program to server.'
		};
	}
});
