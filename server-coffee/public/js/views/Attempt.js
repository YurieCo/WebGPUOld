

window.AttemptView = Backbone.View.extend({
	el: '.analysis-attempt',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.collection = new AttemptElementList();
		this.collection.models = _.map(data, function(elem) {
			return new AttemptElement(elem);
		});
		this.render()
	},
	render: function() {
		$(this.el).html(this.template({
			elements: this.collection.models
		}));
		$(this.el).show();
		return this;
	},
	clear: function() {
		this.collection.clear();
	}
});


