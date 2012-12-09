/**
 * Starts Farabi... :)
 */
function startFarabi(editorId) {

	// Cache dialog jQuery references for later use
	var $perl_critic_dialog = $('#perl-critic-dialog');
	var $about_dialog = $('#about-dialog');
	var $help_dialog = $("#help-dialog");
	var $runDialog = $("#run-dialog");
	var $openFileDialog    = $("#open-file-dialog");
	var $optionsDialog = $("#options-dialog");

	$("#theme_selector").change(function() {
		var $selectedTheme = $(":selected", this);
		var theme = $selectedTheme.val();

		$("head").append("<link>");
		var css = $("head").children(":last");
		css.attr({
			rel:  "stylesheet",
			type: "text/css",
			href: "assets/codemirror/theme/" + theme + ".css"
		});

		editor.setOption("theme", theme);
	});

	function displayHelp(cm) {
		var selection = cm.getSelection();
		if(selection) {
			_displayHelp(selection, true);
		} else {
			// Search for token under the cursor
			var token = cm.getTokenAt(cm.getCursor());
			if(token.string) {
				_displayHelp($.trim(token.string), true);
			} else {
				_displayHelp('', true);
			}
		}
	}

	function _displayHelp(topic, bShowDialog) {
		$.post('/help_search', {"topic": topic}, function(results) {
			if(results.length > 0) {
				$(".topic").val(topic);
				var html = '';
				for(var i = 0; i < results.length; i++) {
					html += '<option value="' + i + '">' + results[i].podname + "  (" + results[i].context + ")" +'</option>';
				}

				$(".results")
					.html(html)
					.change(function() {
						var index = $(':selected', this).val();
						$(".preview").html(results[index].html);
					}).change().show();
			} else {
				$(".topic").val(topic);
				$(".results").html('').hide();
				$(".preview").html('<span class="text-error">No results found!</span>');
			}
			if(bShowDialog) {
				$('a[href="#learn-tab"]').tab('show');
				$(".topic").select().focus();
			}
		});
	}

	function changeMode(cm, modeFile, mode) {
		if(typeof mode == 'undefined') {
			mode = modeFile;
		}
		CodeMirror.modeURL = "assets/codemirror/mode/%N.js";
		cm.setOption("mode", mode);
		CodeMirror.autoLoadMode(cm, modeFile);	
	}

	function plural(number) {
		if(number == 1) {
			return 'st';
		} else if(number == 2) {
			return 'nd';
		} else {
			return 'th';
		}
	}

	function showEditorStats(cm) {
		var cursor = cm.getCursor();
		var selection = cm.getSelection();
		var line_number = cursor.line + 1;
		var column_number = cursor.ch + 1;
		$('#editor_stats').html(
			'<strong>' + line_number + '</strong>' + plural(line_number) + ' line' +
			', <strong>' + column_number + '</strong>' + plural(column_number) + ' column' +
			', <strong>' + cm.lineCount() + '</strong>&nbsp;lines' +
			(selection ?  ', <strong>' + selection.length +'</strong>&nbsp;selected characters' : '')  +
			', <strong>' + cm.getValue().length + '</strong>&nbsp;characters' +
			', <strong>' + cm.lineCount() + '</strong>&nbsp;Lines&nbsp;&nbsp;'
		);
	}

	$("#mode_selector").change(function() {
		var $selectedMode = $(":selected", this);
		var mode = $selectedMode.val();
		if(mode == 'clike') {
			changeMode(editor, mode, 'text/x-csrc');
		} else if(mode == 'plsql') {
			changeMode(editor, mode, 'text/x-plsql');
		} else {
			changeMode(editor, mode);
		}
	});

	var podChanged = function(cm) {
		$.post('/pod2html', {"source": cm.getValue()}, function(html) {
			$('#pod-tab').html(html);
		});
	};

	var editor = CodeMirror.fromTextArea(document.getElementById(editorId), {
		lineNumbers: true,
		matchBrackets: true,
		tabSize: 4,
		indentUnit: 4,
		indentWithTabs: true,
		extraKeys: {
			"F1": function(cm) {
				displayHelp(cm);
			},
		}
	});

	// Hook up with cursor activity event
	editor.on("cursorActivity", function(cm) {
			// Highlight active line
			cm.removeLineClass(hlLine, "background", "activeline");
			hlLine = cm.addLineClass(cm.getCursor().line, "background", "activeline");

			// Highlight selection matches
			cm.matchHighlight("CodeMirror-matchhighlight");

			// Show editor statistics
			showEditorStats(cm);
	});

	// Hook up with cursor activity event
	var timeoutId;
	editor.on("change", function(cm) {
			clearInterval(timeoutId);
			timeoutId = setTimeout(function() {
				podChanged(cm);
				perl_critic();
				pod_check();
			}, 250);
	});

	// Run these when we exit this one
	setTimeout(function() {
		// Editor is by default Perl
		changeMode(editor, 'perl');

		// focus!
		editor.focus();

		// Show editor stats at startup
		showEditorStats(editor);

		// Trigger theme selection
		$("#theme_selector").change();

		// Update POD tab at startup
		podChanged(editor);

		// Run Perl::Critic at startup
		perl_critic();

		// Run Pod::Checker at startup
		pod_check();
	}, 0);

	// Highlight active line
	var hlLine = editor.addLineClass(0, "background", "activeline");

	$(".results").hide();

	var $output = $("#output");

	$(".perl_tidy_button").click(function() {
		$.post('/perl_tidy', {"source": editor.getValue()}, function(data) {
			if(data.error == '') {
				editor.setValue(data.source);
			} else {
				$output.val('Error:\n' + data.error);
			}
		});
	});

	$(".open_file_button").click(function() {
		$openFileDialog.modal('show');
		$("#file", $openFileDialog).val('').focus();
		$("#search-results", $openFileDialog).empty();
		$("#ok-button", $openFileDialog).attr("disabled","disabled");
	});

	$(".open_url_button").click(function() {
		var url = prompt("Please Enter a http/https file location:" + 
			"\ne.g https://raw.github.com/ihrd/uri/master/lib/URI.pm");
		if(!url) {
			return;
		}
		$.post('/open_url',
        	{ "url": url },
           	function(code) {
            	editor.setValue(code);
            }
        );
	});

	$(".options-button").click(function() {
		$optionsDialog.modal('show');
		$("#mode_selector", $optionsDialog).focus();
	});


	$(".run-button").click(function() {
		
		$runDialog.modal('show');
		$("#runtime", $runDialog).focus().change();
	});

	$("#runtime").keypress(function(evt) {
		if(evt.keyCode == 13) {
			$("#ok-button", $runDialog).click();
		}
	});

	var runtimeHelp = {
		"rakudo"    : {
			text    : "<b>Rakudo</b> Perl 6, or simply Rakudo, is a compiler for the Perl 6 programming language. It runs on the Parrot virtual machine.",
			url     : "http://rakudo.org/about",
		},
		"niecza"    : {
			text    : "<b>Niecza</b> is a Perl 6 implementation focusing on optimization and efficient implementation research. It targets the Common Language Runtime (<a href='http://en.wikipedia.org/wiki/Common_Language_Infrastructure' target='_blank'>ECMA-335</a>; implementations are 'Mono' and '.NET').",
			url     : "https://github.com/sorear/niecza/blob/master/README.pod",
		},
		"perl": {
			text    : "<b>Perl 5</b> is a highly capable, feature-rich programming language with over 24 years of development.",
			url     : "http://perl.org",
		},	
		"perlito-6" : {
			text    : "<b>Perlito 6</b> is a compiler collection that implements a subset of Perl 6.",
			url     : "http://perlito.org",
		},
		"perlito-5" : {
			text    : "<b>Perlito 5</b> is a compiler collection that implements a subset of Perl 5.",
			url     : "http://perlito.org",
		},
	};

	$("#runtime").change(function() {
		var runtime = $(":selected", $(this)).attr('id');
		var help = runtimeHelp[runtime];
		$("#help", $runDialog).html(help.text + "<br><a href='" + help.url + "' target='_blank'>More information...</a>");
	});

	$("#ok-button", $runDialog).click(function() {
			
		var runtime = $("#runtime :selected", $runDialog).attr('id');
		if(runtime == "perlito-6") {
			// Perlito 6
			if(typeof p6pkg != 'undefined') {
                                runOnPerlito6(editor.getValue());
                        } else {
                                // Load Perlito and then run
                                $.ajax({
                                        url: 'assets/perlito/perlito6.min.js',
                                        dataType: "script",
                                        success: function() {
                                                runOnPerlito6(editor.getValue());
                                        }
                                });
                        }
		} else if(runtime == "perlito-5") {
			// Perlito 5
			if(typeof p5pkg != 'undefined') {
				runOnPerlito5(editor.getValue());
			} else {
				// Load Perlito and then run
				$.ajax({
					url: 'assets/perlito/perlito5.min.js',
					dataType: "script",
					success: function() {
						runOnPerlito5(editor.getValue());
					}
				});
			}
		} else if(runtime == "perl") { 
			// Perl
			$.post('/run_perl', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "rakudo") {
			// Rakudo Perl 6
			$.post('/run_rakudo', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "niecza") {
			// Niecza
			$.post('/run_niecza', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		}
	});


	var show_cmd_output = function(data) {
		var $output = $('#output');
		$output.val('');
			
		// Handle STDERR
		if (data.stderr.length) {
			$output.val(data.stderr + "\n");
		}
		
		// Handle STDOUT
		$output.val($output.val() + data.stdout + "\nExit code: " + data.exit);
		
		// Show output tab
		$('a[href="#output-tab"]').tab('show');
	};

	var perlCriticWidgets = [];

	var perl_critic = function() {

		$.post('/perl_critic', {"source": editor.getValue(), "severity": $(':selected', '#critic_severity_selector').val()}, function(violations) {
			for (var i = 0; i < perlCriticWidgets.length; i++) {
				editor.removeLineWidget(perlCriticWidgets[i].widget);
			}
			perlCriticWidgets.length = 0;

			if(violations.length > 0) {
				for(var i = 0; i < violations.length; i++) {
					var violation = violations[i];
					var description = violation.description;

					// Add Perl::Critic violation under the editor line
					var msg = $('<div class="farabi-error">' +
						'<span class="farabi-error-icon">!!</span>' + 
						description + '</div>')
						.appendTo(document)
						.get(0);
					perlCriticWidgets.push({
						violation: violation,
						widget:    editor.addLineWidget(violation.line_number - 1, msg, {coverGutter: true, noHScroll: true}),
						node:      msg
					});
				}

				$('.farabi-error').click(function() {
					
					var violation;
					for(var i = 0; i < perlCriticWidgets.length; i++) {
						if(perlCriticWidgets[i].node == this) {
							violation  = perlCriticWidgets[i].violation;
							break;
						}
					} 
					
					if(!violation) {
						return;
					}

					var policy = violation.policy;
					var html = '<strong>Explanation:</strong><br/>' + violation.explanation;
					html += '<br/><strong>Policy:</strong><br/><a target="_blank" href="https://metacpan.org/module/' + policy + '">' + policy + '</a>';
					html += '<br/><strong>Diagnositcs:</strong><br/>' + violation.diagnostics.replace(/\n/g, '<br/>');

					$('#myModalLabel', $perl_critic_dialog).html(
						violation.description
					);
					$('.modal-body', $perl_critic_dialog).html(html);
					$perl_critic_dialog.modal("show");
				});
			}
		});
	};

	$("#critic_severity_selector").change(function() {
		perl_critic();
	});

	var perlCheckerWidgets = [];

	var pod_check = function() {
		$.post('/pod_check', {"source": editor.getValue()}, function(problems) {
			for (var i = 0; i < perlCheckerWidgets.length; i++) {
				editor.removeLineWidget(perlCheckerWidgets[i].widget);
			}
			perlCheckerWidgets.length = 0;

			if(problems.length > 0) {
				for(var i = 0; i < problems.length; i++) {
					var problem = problems[i];

					// Add Pod::Checker warnings/error under the editor line
					var msg = $('<div class="farabi-error">' +
						'<span class="farabi-error-icon">!!</span>' + 
						problem.message + '</div>')
						.appendTo(document)
						.get(0);
					perlCheckerWidgets.push({
						widget:    editor.addLineWidget(problem.line - 1, msg, {coverGutter: true, noHScroll: true}),
					});
				}
			}
		});
	};

	$('.about_button').click(function() {
		if(typeof p5pkg == 'undefined') {
			$.ajax({
				url: 'assets/perlito/perlito5.min.js',
				dataType: "script",
				cache: true,
				success: function() {
					$('#perlito5-version').html(  p5pkg[ "main" ][ "v_]"]);
					//$('#perlito6-version').html( p6pkg[ "main" ][ "v_]"]);
				}
			});
		} else {
			$('#perlito-version').html(p5pkg[ "main" ][ "v_]" ]);
			//$('#perlito6-version').html( p6pkg[ "main" ][ "v_]"]);
		}
		$('#jquery-version').html($().jquery);
		$('#codemirror-version').html(CodeMirror.version);
		$about_dialog.modal("show");
	});

	$('.help_button').click(function() {
		$help_dialog.modal("show");
	});

	var onCloseFocusEditor = function () {
		editor.focus();
	};
	$perl_critic_dialog.hide().on('hidden', onCloseFocusEditor);
	$about_dialog.hide().on('hidden', onCloseFocusEditor);
	$help_dialog.hide().on('hidden', onCloseFocusEditor);
	$runDialog.hide().on('hidden', onCloseFocusEditor);
	$optionsDialog.hide().on('hidden', onCloseFocusEditor);

	$(".topic").typeahead({
		source : function(query, process) {
			$.ajax({
				type: 'POST',
				url: '/typeahead',
				async: false,
				data: {'query': query},
				success: function(matches) {
					process(matches);
				},
				dataType: 'json',
			});
		}
	}).change(function() {
		_displayHelp($(this).val(), true);
	});;

	$("#line_numbers_checkbox").change(function() {
		editor.setOption('lineNumbers', $(this).is(':checked'));
	});

	$("#pod_viewer_checkbox").change(function() {
		if ( $(this).is(':checked') ) {
			$("#pod-tab").addClass("span6").show();
			$("#editor-border").removeClass("span12").addClass("span6");
		} else {
			$("#pod-tab").removeClass("span6").hide();
			$("#editor-border").removeClass("span6").addClass("span12");
		}
	});

	$("#tab_size").change(function() {
		var tabSize = $(this).val();
		if($.isNumeric(tabSize)) {
			$(this).parent().parent().removeClass("error");
			editor.setOption('tabSize', tabSize);
		} else {
			$(this).parent().parent().addClass("error");
		}
	});
}

function runOnPerlito5(source) {

	var $output = $('#output');

	// CORE.print prints to output tab
	p5pkg.CORE.print = function(List__) {
		var i;
		for (i = 0; i < List__.length; i++) {
			$output.val( $output.val() + p5str(List__[i]));
		}
		return true;
	};

	// CORE.warn print to output tab
	p5pkg.CORE.warn = function(List__) {
		var i;
		List__.push("\n");
		for (i = 0; i < List__.length; i++) {
			$output.val( $output.val() + p5str(List__[i]));
		}
		return true;
	};

	// Define version, strict and warnings
	p5pkg["main"]["v_^O"] = "browser";
	p5pkg["main"]["Hash_INC"]["Perlito5/strict.pm"] = "Perlito5/strict.pm";
	p5pkg["main"]["Hash_INC"]["Perlito5/warnings.pm"] = "Perlito5/warnings.pm";

	p5make_sub("Perlito5::IO", "slurp", function(filename) {
		console.error('IO.slurp "' + filename + '"');
		return 1;
	});

	p5is_file = function(filename) {
		console.error('p5is_file "' + filename + '"');
		return 1;
	}

	// Clear up output
	$output.val('');

	try {
		// Compile Perl 5 source code into JavaScript
		var start = $.now();
		var js_source = p5pkg["Perlito5"].compile_p5_to_js([source]);

		// Run JavaScript inside your browser
		start = $.now();;
		eval(js_source);

	}
	catch(err) {
		// Populate error and show error in output tab
		$output.val("Error:\n" + err + "\nCompilation aborted.\n");
	}

	// Show output tab
	$('a[href="#output-tab"]').tab('show');

}

function runOnPerlito6(source) {
	var $output = $('#output');
	window.print = function(s) {
		$output.val($output.val() + s + "\n");
	}
        var ast;
	var match;
	$output.val('');
	try {
                // compilation unit
                match = Perlito6$Grammar.exp_stmts(source, 0);
                ast = match.scalar();
                tmp = {v_name:"GLOBAL", v_body: ast}; 
                tmp.__proto__ = CompUnit; 
                ast = tmp;
		eval(ast.emit_javascript());
	} catch(err) {
                // Show error in output tab
                $output.val("Error:\n" + perl(err) + "\nCompilation aborted.\n");
	}

        // Show output tab
        $('a[href="#output-tab"]').tab('show');
}

// Start Farabi when the document loads
$(function() {
	startFarabi("editor");
});
