
var AttemptElementList = Backbone.Collection.extend({
	model: AttemptElement,
	comparator: function(attempt) {
		return attempt.get('created_on');
	}
});
