

window.ThrottledView = Backbone.View.extend({
	el: '.throttled-modal',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new Throttled(data);
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});

