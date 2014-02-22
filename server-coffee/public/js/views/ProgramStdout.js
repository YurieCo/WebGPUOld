
window.ProgramStdoutView = Backbone.View.extend({
	el: '.analysis-program-stdout',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new ProgramStdout({Type: 'ProgramStdout', Data: data});
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});
