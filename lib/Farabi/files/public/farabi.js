/**
 * Starts Farabi... :)
 */
function startFarabi(editorId) {

	// Cache dialog jQuery references for later use
	var $perl_critic_dialog = $('#perl_critic_dialog');
	var $about_dialog = $('#about_dialog');
	var $help_dialog = $("#help_dialog");

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

		humane.log("Mode changed to " + $selectedTheme.html());
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
				humane.log("Found " + results.length + " help results for '" + topic +"'!");
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
				humane.log("No help found for '" + topic + "'");

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
		humane.log("Mode changed to " + $selectedMode.html());
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
			"F5": function(cm) {
				$(".run_in_browser_button").click();
			}
		}
	});

	// Hook up with cursor activity event
	editor.on("cursorActivity", function(cm) {
			// Highlight active line
			cm.setLineClass(hlLine, null, null);
			hlLine = cm.setLineClass(cm.getCursor().line, null, "activeline");

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

		// Update POD tab at startup
		podChanged(editor);

		// Run Perl::Critic at startup
		perl_critic();

		// Run Pod::Checker at startup
		pod_check();
	}, 0);

	// Highlight active line
	var hlLine = editor.setLineClass(0, "activeline");

	$(".results").hide();

	$(".run_in_browser_button").click(function() {
		// Load Perlito - Perl 5 to JS Compiler
		humane.log("Loading Perlito 5");
		$.ajax({
			url: 'assets/perlito/perlito5.min.js',
			dataType: "script",
			cache: true,
			success: function() {
				runOnPerlito(editor.getValue());
				humane.log("Run in browser finished");
			}
		});
	});

	var $output = $("#output");

	$(".perl_tidy_button").click(function() {
		$.post('/perl_tidy', {"source": editor.getValue()}, function(data) {
			if(data.error == '') {
				editor.setValue(data.source);
				humane.log("Your code is tidied!");
			} else {
				$output.val('Error:\n' + data.error);
				humane.log("Perl::Tidy failed! Please check output");
			}
		});
	});

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
			humane.log("Loading Perlito 5");
			$.ajax({
				url: 'assets/perlito/perlito5.min.js',
				dataType: "script",
				cache: true,
				success: function() {
					$('#perlito-version').html(  p5pkg[ "main" ][ "v_]"]);
					humane.log("Perlito 5 loaded");
				}
			});
		} else {
			$('#perlito-version').html(p5pkg[ "main" ][ "v_]" ]);
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

function runOnPerlito(source) {

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

// Start Farabi when the document loads
$(function() {
	startFarabi("editor");
});
