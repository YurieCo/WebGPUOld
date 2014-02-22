

window.LoggerElementView = Backbone.View.extend({
	initialize: function() {
		_.bindAll(this, 'render');
		this.model.bind("change", this.render, this);
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		return this;
	}
});

