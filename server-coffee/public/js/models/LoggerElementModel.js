var LoggerElement = Backbone.Model.extend({
	initialize: function(data) {
		level = this.get("Level");
		cssClass = "text-info";
        if (level == "Error") {
            cssClass = "text-error";
        } else if (level == "Off") {
            cssClass = "muted";
        } else if (level == "Warn") {
            cssClass = "text-warning";
        } else if (level == "Fatal") {
            cssClass = "text-error";
        } else if (level == "Info") {
            cssClass = "text-success";
        } else if (level == "Trace") {
            cssClass = "text-info";
        } else {
            cssClass = "text-info";
        }
	this.set("Class", cssClass);
	},
	defaults: function() {
		return {
			Type: null,
			File: null,
			Function: null,
			Level: null,
			Message: null,
            Class: "text-info",
			Time: 0
		};
	}
});
