var Data = Backbone.Model.extend({
	defaults: function() {
		return {
			input: [],
			output: "",
			expected: ""
		};
	}
});
