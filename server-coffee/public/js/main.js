$(function() {
    var load_attempt = function(mp_id, attempt_id) {
        templateLoader.load([
            'CompilerStderrView',
            'CompilerStdoutView',
            'CompilerFailedView',
            'SubmissionFailedView',
            'LoggerView',
            'LoggerElementView',
            'ProgramStderrView',
            'ProgramStdoutView',
            'ProgramFailedView',
            'TimerView',
            'TimerElementView',
            'AttemptView',
            'AttemptElementView',
            'InputView',
            'OutputView',
            'ExpectedView',
            'DataView',
            'SandboxedView',
            'ThrottledView'
        ], function() {

            window.editor = CodeMirror.fromTextArea($("#static-code-editor")[0], {
                mode: "text/x-cudasrc",
                lineNumbers: true,
                theme: "eclipse",
				readOnly: true
            });
			$("#static-code-editor").hide();

            $.ajax({
                type: 'GET',
                async: true,
                url: '/mp/' + mp_id + '/attempt_description/' + attempt_id,
                success: function(msg) {
                    $('.analysis-code').removeClass('hide');
					if (msg.ProgramText) {
							$("#static-code-editor").removeClass('hide');
							editor.setSize(null, '80%');
							editor.setValue(msg.ProgramText);
							editor.refresh();
					}
					if (msg.ProgramTimer)
						var timerView = new TimerView(msg.ProgramTimer);
					if (msg.ProgramLogger)
						var loggerView = new LoggerView(msg.ProgramLogger);
					if (msg.CompilerStderrOutput)
						var compilerStderrView = new CompilerStderrView(msg.CompilerStderrOutput);
					if (msg.CompilerStdoutOutput)
						var compilerStdoutView = new CompilerStdoutView(msg.CompilerStdoutOutput);
					if (msg.ProgramStderrOutput)
						var programStderrView = new ProgramStderrView(msg.ProgramStderrOutput);
					if (msg.ProgramStdoutOutput)
						var programStdoutView = new ProgramStdoutView(msg.ProgramStdoutOutput);
                }
            })
		})
    };	
    var load_mp = function(mp_id) {
        templateLoader.load([
            'CompilerStderrView',
            'CompilerStdoutView',
            'CompilerFailedView',
            'SubmissionFailedView',
            'LoggerView',
            'LoggerElementView',
            'ProgramStderrView',
            'ProgramStdoutView',
            'ProgramFailedView',
            'TimerView',
            'TimerElementView',
            'AttemptView',
            'AttemptElementView',
            'InputView',
            'OutputView',
            'ExpectedView',
            'DataView',
            'SandboxedView',
            'ThrottledView'
        ], function() {

            window.editor = CodeMirror.fromTextArea($("#code-editor")[0], {
                mode: "text/x-cudasrc",
                lineNumbers: true,
                theme: "eclipse"
            });

            $('#tab-interface a[data-toggle="tab"][href="#code"]').on('shown', function (e) {
                window.editor.refresh();
            })

            $.get('/mp/' + mp_id + '/description', function(data) {
                $('.problem-description').html(data)
            });
            $('.dropdown-toggle').dropdown();
            $('.nav-mp' + mp_id).addClass('active');
            if (! _.isUndefined($.Tour)) {
                var tour = $.Tour();
            }

            var show_analysis_tab = function() {
                $.ajax({
                    type: 'GET',
                    async: true,
                    url: '/mp/' + mp_id + '/attempt_summary',
                    success: function(data) {
                        var attemptView = new AttemptView(data);
                        $('.analysis').removeClass('hide');
                        $('.analysis > .accordion').collapse({
                            toggle: false
                        });
                    }
                })
            };

            var old_program = "";

            var save_program = function() {
                var program = editor.getValue();
                if (program == old_program) {
                    return ;
                }
                $.ajax({
                    type: 'POST',
                    async: true,
                    url: '/mp/' + mp_id + '/save_program',
                    data: {
                        "Type" : "Program",
                        "Data": program
                    },
                    timeout: 600000,
                    dataType: 'json',
                    success: function(msg) {
                        old_program = program;
                    }
                })
            };

            var autosave_program = function() {
                setInterval(save_program, 3000);
            };

            $.get('/mp/' + mp_id + '/program', function(data) {
                editor.setSize(null, '80%');
                editor.setValue(data);
                autosave_program();
                show_analysis_tab();
            }).done(function() {
                $('.compute-btn-group').show();
                $('.compute-btn').button().click(function(e) {
                    var selected_dataset = _.find($(".dataset-id").children(), function(child) {
                        return child.selected;
                    });
                    var dataset_id = selected_dataset.id;
                    $.ajax({
                        type: 'POST',
                        async: true,
                        url: '/mp/' + mp_id + '/submit',
                        data: {
                            "Type" : "Program",
                            "Data": editor.getValue(),
                            dataset_id: dataset_id
                        },
                        timeout: 600000,
                        dataType: 'json',
                        beforeSend: function() {
                            $('.compute-btn-group').hide();
                            $('.computing').show();
                            $('.spinner').spin({
                                left: 80,
                                top: -30,
                                length: 3,
                                lines: 9,
                                width: 8,
                                radius: 9,
                            });
                        },
                        complete: function() {
                            $('.spinner').spin(false);
                            $('.compute-btn-group').show();
                            $('.computing').hide();
                        },
                        error: function(jqXHR, textStatus, errorThrown) {
                            var message;
                            if (textStatus == "timeout") {
                                message = "Reached timeout to submit program to server.";
                            } else {
                                message = "Failed to submit program to server.";
                            }
                            var submissionFailedView = new SubmissionFailedView({
                                message: message,
                            });
                            $('.submission-failed-modal').modal();
                        },
                        success: function(msg) {
                            if (msg) {
                                if (msg.Throttled) {
                                    var throttledView = new ThrottledView({
                                    });
                                    $('.throttled-modal').modal();
                                } else if (msg.Sandboxed) {
                                    var sandboxedView = new SandboxedView({
                                        keyword: msg.SandboxedKeyword
                                    });
                                    $('.sandboxed-modal').modal();
                                } else if (msg.CompileFailed) {
                                    //var compilerStderrView = new CompilerStderrView(msg.CompilerStderrOutput);
                                    //var compilerStdoutView = new CompilerStdoutView(msg.CompilerStdoutOutput);
                                    var compilationFailedView = new CompilerFailedView({
                                        message: msg.CompileFailed,
                                        stderr: msg.CompilerStderrOutput,
                                        stdout: msg.CompilerStdoutOutput,
                                    });
                                    $('.compiler-failed-modal').modal();
                                } else if (msg.ProgramFailed) {
                                    //var programStderrView = new ProgramStderrView(msg.ProgramStderrOutput);
                                    //var programStdoutView = new ProgramStdoutView(msg.ProgramStdoutOutput);
                                    var programFailedView = new ProgramFailedView({
                                        message: msg.ProgramFailed,
                                        stderr: msg.ProgramStderrOutput,
                                        stdout: msg.ProgramStdoutOutput
                                    });
                                    $('.program-failed-modal').modal();
                                } else {
                                    if (msg.ProgramTimer)
                                        var timerView = new TimerView(msg.ProgramTimer);
                                    if (msg.ProgramLogger)
                                        var loggerView = new LoggerView(msg.ProgramLogger);
                                    if (msg.CompilerStderrOutput)
                                        var compilerStderrView = new CompilerStderrView(msg.CompilerStderrOutput);
                                    if (msg.CompilerStdoutOutput)
                                        var compilerStdoutView = new CompilerStdoutView(msg.CompilerStdoutOutput);
                                    if (msg.ProgramStderrOutput)
                                        var programStderrView = new ProgramStderrView(msg.ProgramStderrOutput);
                                    if (msg.ProgramStdoutOutput)
                                        var programStdoutView = new ProgramStdoutView(msg.ProgramStdoutOutput);
                                    $('#tab-interface a[href="#analysis"]').tab('show');
                                }
                                show_analysis_tab();
                            }
                            return ;
                        },
                    })
                });
            });

        });
    };

    var load_help = function() {
        $.get('/description', function(data) {
            $('.description').html(data);
            var imgs = $('.description').find('p > a > img');
            var links = imgs.parent();
            links.parent().addClass('center-img');
            links.attr("rel", "lightbox");
        });
    };

    var is_attempt = function(path) {
        return path.indexOf("/attempt") != -1;
    };

    var is_mp = function(path) {
        return path.indexOf("/mp") != -1;
    };

    var is_help = function(path) {
        return path.indexOf("/help") != -1;
    };

    var path_name = window.location.pathname;

    if (is_attempt(path_name)) {
		var mp_id = path_name.replace(/.*\/mp\/?/g,'').replace(/\/.*/g, '');
        var attempt_id = path_name.replace(/.*\/attempt\/?/g, '');
        if (_.isString(attempt_id)) {
            attempt_id = parseInt(attempt_id);
            attempt_id = "" + attempt_id;
        }
        if (_.isString(mp_id)) {
            mp_id = parseInt(mp_id);
            mp_id = "" + mp_id;
        }
        load_attempt(mp_id, attempt_id);
    } else if (is_mp(path_name)) {
        var mp_id = path_name.replace(/\/mp\/?/g,'');
        if (_.isString(mp_id)) {
            mp_id = parseInt(mp_id);
            mp_id = "" + mp_id;
        }
        load_mp(mp_id);
    } else if (is_help(path_name)) {
        load_help();
    }
});


