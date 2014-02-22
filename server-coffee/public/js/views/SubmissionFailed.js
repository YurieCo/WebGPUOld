

window.SubmissionFailedView = Backbone.View.extend({
	el: '.submission-failed-modal',
	initialize: function(data) {
		_.bindAll(this, 'render');
		this.model = new SubmissionFailed(data);
		this.render();
	},
	render: function() {
		$(this.el).html(this.template(this.model.toJSON()));
		$(this.el).show();
		return this;
	}
});

