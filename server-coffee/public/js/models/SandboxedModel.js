var Sandboxed = Backbone.Model.extend({
	initialize: function(data) {
		this.keyword = $.trim(data.keyword);
	},
	defaults: function() {
		return {
			message: 'Invalid operation in sandbox.',
			keyword: null
		};
	}
});

