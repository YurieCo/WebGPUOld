

window.ProgramFailedView = Backbone.View.extend({
	el: '.program-failed-modal',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new ProgramFailed(data);
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});

