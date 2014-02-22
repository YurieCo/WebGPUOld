var ProgramStderr = Backbone.Model.extend({
	initialize: function(data) {
		this.Type = data.Type;
		this.Data = $.trim(data.Data);
	},
	defaults: function() {
		return {
			Type: null,
			Data: null
		};
	}
});
