

window.UserView = Backbone.View.extend({
	el: '.user',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new User(data);
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});


