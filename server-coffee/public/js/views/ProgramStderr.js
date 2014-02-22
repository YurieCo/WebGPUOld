
window.ProgramStderrView = Backbone.View.extend({
	el: '.analysis-program-stderr',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new ProgramStderr({Type: 'ProgramStderr', Data: data});
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});
