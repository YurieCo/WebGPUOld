

window.CompilerFailedView = Backbone.View.extend({
	el: '.compiler-failed-modal',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new CompilerFailed(data);
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});

