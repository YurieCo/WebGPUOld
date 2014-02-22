
window.CompilerStdoutView = Backbone.View.extend({
	el: '.analysis-compiler-stdout',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new CompilerStdout({Type: 'CompilerStdout', Data: data});
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});
