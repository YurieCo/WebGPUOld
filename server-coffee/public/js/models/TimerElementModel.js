

var TimerElement = Backbone.Model.extend({
	defaults: function() {
		return {
			Type: null,
			Id: -1,
			StoppedQ: false,
			Kind: null,
			StartTime: -1,
			EndTime: -1,
			ElapsedTime: -1,
			StartLine: -1,
			EndLine: -1,
			StartFunction: -1,
			EndFunction: -1,
			StartFile: null,
			EndFile: null,
			ParentId: -1,
			Message: null
		};
	}
});

