


window.CompilerStderrView = Backbone.View.extend({
	el: '.analysis-compiler-stderr',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new CompilerStderr({Type: 'CompilerStderr', Data: data});
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});