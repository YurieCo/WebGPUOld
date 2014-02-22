var AttemptElement = Backbone.Model.extend({
	initialize: function(data) {
		if (this.get('compile_failed') ||
			this.get('program_failed') ||
			this.get('correct') == false) {
			this.set('tr_class', "error");
		} else {
			this.set('tr_class', "success");
		}
		if (data.program_failed) {
			this.set('message', 'Program execution failed');
		} else if (data.compile_failed) {
			this.set('message', 'Compilation failed');
		} else {
			this.set('message', data.solution_message);
		}
		if (this.get('dataset_id') == -1) {
			this.set('dataset_id', '');
		}
		if (this.get('id') == -1 || this.get('id') == null) {
			this.set('id', null);
			this.set('attempt_link', null);
		} else {
			this.set('attempt_link', window.location.pathname + "/attempt/" + this.get('id'));
		}
		return this;
	},
	defaults: function() {
		return {
			id: null,
			elapsed_time: -1,
			created_on: -1,
			run_time: 0,
			dataset_id: -1,
			solution_mesasge: "",
			correct: false,
			compile_failed: false,
			program_failed: false,
            program_link: null
		};
	}
});

