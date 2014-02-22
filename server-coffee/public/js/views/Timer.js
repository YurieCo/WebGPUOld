

var prev_line = 0;

window.TimerView = Backbone.View.extend({
	el: '.analysis-timer',
	events: {
		"click .kind-th": "sort_by_kind",
		"click .line-th": "sort_by_line",
		"click .message-th": "sort_by_message",
		"click .elapsed-time-th": "sort_by_elapsed_time",
		"click .timer-element-row": "highlight_program_line",
	},
	toggle: [],
	initialize: function(data) {
        if (_.isEmpty(data.Elements)) {
            return ;
        }

		_.bindAll(this, 'render',
						'sort_by_kind',
						'sort_by_line',
						'sort_by_message',
						'sort_by_elapsed_time',
						'highlight_program_line'
		);
		this.toggle['clicked_elapsed_time'] = false;
		this.toggle['clicked_kind'] = false;
		this.toggle['clicked_message'] = false;
		this.toggle['clicked_line'] = false;
		this.collection = new TimerElementList(data.Elements);
		this.render()
	},
	render: function() {
		$(this.el).html(this.template({elements: this.collection.models}));
		$(this.el).show();
		return this;
	},
	sortBy: function(sortFunction, order) {
		var nc = this.collection.sortBy(function(elem) {
			return sortFunction(elem);
		});
		if (order == false) {
			nc = nc.reverse();
		}
		this.collection.reset(nc);
		this.render();
	},
	sort_by_elapsed_time: function() {
		this.toggle['clicked_elapsed_time'] ^= true;
		this.sortBy(function(elem) {
			var time = elem.get('ElapsedTime');
			return format_time(time)
		}, this.toggle['clicked_elapsed_time']);
	},
	sort_by_line: function() {
		this.toggle['clicked_line'] ^= true;
		this.sortBy(function(elem) {
			var line = elem.get('StartLine');
			return line
		}, this.toggle['clicked_line']);
	},
	sort_by_kind: function() {
		this.toggle['clicked_kind'] ^= true;
		this.sortBy(function(elem) {
			var kind = elem.get('Kind');
			return kind;
		}, this.toggle['clicked_kind']);
	},
	sort_by_message: function() {
		this.toggle['clicked_message'] ^= true;
		this.sortBy(function(elem) {
			var message = elem.get('Message');
			return message;
		}, this.toggle['clicked_message']);
	},
	highlight_program_line: function(data) {
		try {
			var line = parseInt(data.target.parentNode['id']);
			editor.setLineClass(prev_line, null, null);
			editor.setLineClass(line, null, "activeline");
			if (line - 4 < 0) {
				editor.setCursor(line, 0);
			} else {
				editor.setCursor(line - 4, 0);
			}
			prev_line = line;
		} catch(e) {
		}
	},
	clear: function() {
		this.collection.clear();
	}
});


