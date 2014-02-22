// The Template Loader. Used to asynchronously load templates located in separate .html files
window.templateLoader = {

    load: function(views, callback) {

        var deferreds = [];

        $.each(views, function(index, view) {
            if (window[view]) {
                deferreds.push($.get('/public/template/' + view + '.html', function(data) {
                    window[view].prototype.template = _.template(data);
                }, 'html'));
            }
        });

        $.when.apply(null, deferreds).done(callback);
    }

};

$.fn.spin = function(opts) {
    this.each(function() {
        var $this = $(this),
            data = $this.data();

        if (data.spinner) {
            data.spinner.stop();
            delete data.spinner;
        }
        if (opts !== false) {
            data.spinner = new Spinner($.extend({color: $this.css('color')}, opts)).spin(this);
        }
    });
    return this;
};

var format_time = function(time) {
    if (typeof time == 'number') {
        return time/1e9;
    } else if (time instanceof Array) {
        var sec = time[0];
        var nsec = time[1] / 1e9;
        return sec + nsec;
    } else {
        return 0;
    }
};
