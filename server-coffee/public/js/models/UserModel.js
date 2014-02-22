var User = Backbone.Model.extend({
	initialize: function(data) {
		this.name = $.trim(data.name);
	},
	defaults: function() {
		return {
			name: ''
		};
	}
});


