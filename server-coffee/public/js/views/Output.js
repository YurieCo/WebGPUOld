

window.OutputView = Backbone.View.extend({
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new Output(data);
		this.model.bind("change", this.render, this);
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		return this;
	}
});

