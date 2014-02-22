

window.LoggerView = Backbone.View.extend({
	el: '.analysis-logger',
	initialize: function(data) {

		_.bindAll(this, 'render');
		this.collection = new LoggerElementList(data.Elements);
		this.render()
	},
	render: function() {
		$(this.el).html(this.template({elements: this.collection.models}));
		$(this.el).show();
		return this;
	},
	clear: function() {
		this.collection.clear();
	}
});


