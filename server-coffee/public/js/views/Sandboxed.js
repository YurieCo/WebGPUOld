

window.SandboxedView = Backbone.View.extend({
	el: '.sandboxed-modal',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new Sandboxed(data);
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});

