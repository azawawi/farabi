
// Start Farabi when the document loads
$(function() {
	var editorId = "editor";
	
	// Cache dialog jQuery references for later use
	var $perlCriticDialog = $('#perl-critic-dialog');
	var $about_dialog = $('#about-dialog');
	var $help_dialog = $("#help-dialog");
	var $runDialog = $("#run-dialog");
	var $openFileDialog    = $("#open-file-dialog");
	var $actionsDialog    = $("#actions-dialog");
	var $optionsDialog = $("#options-dialog");
	var $perlDocDialog = $("#perl-doc-dialog");

	$("#theme_selector").change(function() {
		var $selectedTheme = $(":selected", this);
		var theme = $selectedTheme.val();

		if (theme != "default") {
			// Load theme CSS dynamically if it is not default
			$("head").append("<link>");
			var css = $("head").children(":last");
			css.attr({
				rel:  "stylesheet",
				type: "text/css",
				href: "assets/codemirror/theme/" + theme + ".css"
			});
		}
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
				$(".topic").select().focus();
			}
		});
	}

	function changeMode(cm, modeFile, mode) {
		if(typeof mode == 'undefined') {
			mode = modeFile;
		}
		CodeMirror.modeURL = "assets/codemirror/mode/%N/%N.js";
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
			'Alt-A': function(cm) {
				$(".actions-button").click();
			}
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
				var mode = cm.getOption("mode");
				if(mode == "perl") {
					podChanged(cm);
					podCheck();
				} else {
					$("#pod-tab").html('Not supported for mode "' + mode + '"');
				}
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

		var mode = editor.getOption("mode");
		if(mode == "perl") {
			// Update POD tab at startup
			podChanged(editor);

			// Run Pod::Checker at startup
			podCheck();
		} else {
			$("#pod-tab").html('Not supported for mode "' + mode + '"');
		}

	}, 0);

	// Highlight active line
	var hlLine = editor.addLineClass(0, "background", "activeline");

	$(".results").hide();

	$("#ok-button", $actionsDialog).click(function() {
		
		var $selectedAction = $("#matched-actions :selected", $actionsDialog);
		if($selectedAction.size() > 0) {
			var actionId = $selectedAction.attr('id');
			$actionsDialog.modal('hide');
			$(document).trigger(actionId);
		} else {
			alert("No action is selected");
		}
	});

	$(".actions-button").click(function() {
		$actionsDialog.modal('show');
		$("#action").val('');
		$("#action").focus();
		findAction();
	});
	
	var findAction = function() {
		var action = $("#action", $actionsDialog).val();
		$("#matched-actions", $actionsDialog).empty();
		$("#ok-button", $actionsDialog).attr("disabled","disabled");
		$.ajax({
			type:    "POST",
			url:     "/find-action",
			data:    { "action": action },
			success: function(matches) {
				var html = '';
				for(var i = 0; i < matches.length; i++) {
					var a = matches[i];
					html += "<option id='" + a.id + "' "  + 
						((i == 0) ? "selected" : "") + 
						">" + 
						a.name + 
						"</option>";
				}
				if(matches.length > 0) {
					$("#ok-button", $actionsDialog).removeAttr("disabled");
				}
				$("#matched-actions", $actionsDialog).html(html);
			},
			error:   function(jqXHR, textStatus, errorThrown) {
				console.error("Error:\n" + textStatus + "\n" + errorThrown);
			}
		});
	}

	var findActionTimeoutId;
	$("#action", $actionsDialog).on('input', function() {
		clearTimeout(findActionTimeoutId);
		findActionTimeoutId = setTimeout(findAction, 250);
	});

	$("#action", $actionsDialog).keyup(function(evt) {
		var keyCode = evt.keyCode;
		if(keyCode == 40) {
			$("#matched-actions", $actionsDialog).focus();
		} else if(keyCode == 13) {
			var $okButton = $("#ok-button", $actionsDialog);
			if(!$okButton.attr('disabled')) {
				$okButton.click();
			}
		}
	});
	
	var findFile = function() {
		var filename = $("#file", $openFileDialog).val();
		$("#matched-files", $openFileDialog).empty();
		$("#ok-button", $openFileDialog).attr("disabled","disabled");
		$.ajax({
			type:    "POST",
			url:     "/find-file",
			data:    { "filename": filename },
			success: function(results) {
				var html = '';
				for(var i = 0; i < results.length; i++) {
					var result = results[i];
					html += "<option id='" + result.id + "' "  + 
						((i == 0) ? "selected" : "") + 
						">" + 
						result.name + 
						"</option>";
				}
				$("#ok-button", $openFileDialog).removeAttr("disabled");
				$("#matched-files", $openFileDialog).html(html);
			},
			error:   function(jqXHR, textStatus, errorThrown) {
				console.error("Error:\n" + textStatus + "\n" + errorThrown);
			}
		});
	}

	var findFileTimeoutId;
	$("#file", $openFileDialog).on('input', function() {
		clearTimeout(findFileTimeoutId);
		findFileTimeoutId = setTimeout(findFile, 500);
	});

	$("#file", $openFileDialog).keyup(function(evt) {
		var keyCode = evt.keyCode;
		if(keyCode == 40) {
			$("#matched-files", $openFileDialog).focus();
		} else if(keyCode == 13) {
			var $okButton = $("#ok-button", $openFileDialog);
			if(!$okButton.attr('disabled')) {
				$okButton.click();
			}
		}
	});

	$("#ok-button", $openFileDialog).click(function() {
		var filename = $("#matched-files option:selected", $openFileDialog).attr('id');
		if (!filename) {
			console.warn("file name is empty");
			return;
		}
		$.ajax({
			type:    "POST",
			url:     "/open-file",
			data:    { "filename": filename },
			success: function(result) {
				if(result.ok) {
					editor.setValue(result.value);
					changeMode(editor, result.mode);
				} else {
					alert(result.value);
				}
			},
			error:   function(jqXHR, textStatus, errorThrown) {
				console.error("Error!" + textStatus + ", " + errorThrown);
			}
		});
	});

	
	$(document).on('action-perl-doc', function() {
		$perlDocDialog.modal('show');
	});

	$(document).on('action-perl-tidy', function() {
		var $output = $('#output');
		$.post('/perl-tidy', {"source": editor.getValue()}, function(data) {
			if(data.error == '') {
				editor.setValue(data.source);
			} else {
				$output.val('Error:\n' + data.error);
			}
		});
	});

	$(document).on('action-open-file', function() {
		$openFileDialog.modal('show');
		$("#file", $openFileDialog).val('').focus();
		$("#matched-files", $openFileDialog).empty();
		$("#ok-button", $openFileDialog).attr("disabled","disabled");
		findFile();
	});

	$(document).on('action-open-url', function() {
		var url = prompt("Please Enter a http/https file location:" + 
			"\ne.g https://raw.github.com/ihrd/uri/master/lib/URI.pm");
		if(!url) {
			alert("No URL was provided! Aborting");
			return;
		}
		$.post('/open-url',
			{ "url": url },
			function(code) {
				editor.setValue(code);
			}
		);
	});

	$(document).on('action-syntax-check', function() {
		alert("TODO syntax check");
	});

	$(document).on('action-perl-critic', function() {
		perlCritic();
	});

	$(document).on('action-options', function() {
		$optionsDialog.modal('show');
		$("#mode_selector", $optionsDialog).focus();
	});

	$(document).on('action-run', function() {
		// Run file
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
		"parrot"    : {
			text   : "<b>Parrot</b> is a virtual machine designed to efficiently compile and execute bytecode for dynamic languages.",
			url    : "http://www.parrot.org/",
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
		} else if(runtime == "parrot") {
			// Rakudo Perl 6
			$.post('/run_parrot', {"source": editor.getValue() }, function(result) {
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
	};

	var perlCriticWidgets = [];

	var perlCritic = function() {

		$.post('/perl-critic', {"source": editor.getValue(), "severity": $(':selected', '#critic_severity_selector').val()}, function(violations) {
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

					$('#myModalLabel', $perlCriticDialog).html(
						violation.description
					);
					$('.modal-body', $perlCriticDialog).html(html);
					$perlCriticDialog.modal("show");
				});
			}
			
			if(violations.length > 0) {
				alert("Perl Critic: Found " + violations.length + " violation(s)");
			} else {
				alert("Perl Critic: No violations found for current severity level");
			}
		});
	};

	$("#critic_severity_selector").change(function() {
		perlCritic();
	});

	var perlCheckerWidgets = [];

	var podCheck = function() {
		$.post('/pod-check', {"source": editor.getValue()}, function(problems) {
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

	$(document).on('action-about', function() {
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

	$(document).on('action-help', function() {
		$help_dialog.modal("show");
	});

	var onCloseFocusEditor = function () {
		editor.focus();
	};

	// All modal dialogs are now hidden on startup
	// And when hidden event is trigged, the focus is changed
	// to the current editor
	$(".modal").hide().on('hidden', onCloseFocusEditor);

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
});

var runOnPerlito5 = function(source) {

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

};

var runOnPerlito6 = function(source) {
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
};