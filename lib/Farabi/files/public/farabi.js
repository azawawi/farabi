
// Start Farabi when the document loads
$(function() {
	var editorId = "editor";
	
	// Cache dialog jQuery references for later use
	var $about_dialog = $('#about-dialog');
	var $help_dialog = $("#help-dialog");
	var $perlDocDialog = $("#perl-doc-dialog");

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

	// Editors hash object
	var editors = {};

	var tabId = 1;
	window.AddEditorTab = function(tabName) {
		
		if(!tabName) {
			// Tab name
			tabName = "Untitled " + tabId;
		}
		
		// Generate editor id
		editorId = "editor" + tabId;

		// Add the tab component
		$("#myTab").append('<li><a href="#' + tabId + '" data-toggle="tab">' + tabName + '</a></li>');

		// Add the tab editor
		$("#myTabContent").append(
			'<div class="tab-pane" id="' + tabId + '">' +
				'<div class="span6 farabi-bordered" id="editor-border">' +
					'<b>Editor:</b>' +
					'<textarea id="'+editorId+'" name="' + editorId +'" class="editor"></textarea>' +
					'<div class="editor_stats" class="pull-right"></div>' +
				'</div>' +
				'<div class="span6 farabi-bordered">' +
					'<b>POD  Preview:</b>' + 
					'<div  id="pod-tab">' +
					'</div>' +
				'</div>' +
			'</div>');
		
		// Create the CodeMirror editor instance
		var editor = CodeMirror.fromTextArea(document.getElementById(editorId), {
			//TODO these should be configurable!
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

		
		// Store editor reference
		editors[editorId] = editor;
		
		// This is the current editor
		currentEditor = editor;

		// Show the last editor tab which we added
		var $lastTab = $("#myTab a:last");
		$lastTab.tab('show');
		
		// And refresh the editor once it is shown
		$lastTab.on('shown', function (e) {
			editor.refresh();
		});

		// Run these when we exit this one
		setTimeout(function() {
			// Editor is by default Perl
			ChangeMode(editor, 'perl');

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
		
		tabId++;
	};
	

	// Add an empty one editor tab on startup
	AddEditorTab();

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

	window.ChangeMode = function(cm, modeFile, mode) {
		if(typeof mode == 'undefined') {
			mode = modeFile;
		}
		CodeMirror.modeURL = "assets/codemirror/mode/%N/%N.js";
		cm.setOption("mode", mode);
		CodeMirror.autoLoadMode(cm, modeFile);	
	}

	var plural = function(number) {
		if(number == 1) {
			return 'st';
		} else if(number == 2) {
			return 'nd';
		} else {
			return 'th';
		}
	}

	var showEditorStats = function(cm) {
		var cursor = cm.getCursor();
		var selection = cm.getSelection();
		var line_number = cursor.line + 1;
		var column_number = cursor.ch + 1;
		$('.editor_stats').html(
			'<strong>' + line_number + '</strong>' + plural(line_number) + ' line' +
			', <strong>' + column_number + '</strong>' + plural(column_number) + ' column' +
			', <strong>' + cm.lineCount() + '</strong>&nbsp;lines' +
			(selection ?  ', <strong>' + selection.length +'</strong>&nbsp;selected characters' : '')  +
			', <strong>' + cm.getValue().length + '</strong>&nbsp;characters' +
			', <strong>' + cm.lineCount() + '</strong>&nbsp;Lines&nbsp;&nbsp;'
		);
	}

	var podChanged = function(cm) {
		$.post('/pod2html', {"source": cm.getValue()}, function(html) {
			$('#pod-tab').html(html);
		});
	};

	/** Get the current editor */
	window.GetCurrentEditor = function() {
		//TODO return a better one :)
		return currentEditor;
	};
	
	$(".results").hide();

	$(document).on('action-perl-doc', function() {
		$perlDocDialog.modal('show');
	});

	$(document).on('action-perl-tidy', function() {
		var $output = $('#output');
		var editor = GetCurrentEditor();
		$.post('/perl-tidy', {"source": editor.getValue()}, function(data) {
			if(data.error == '') {
				editor.setValue(data.source);
			} else {
				$output.val('Error:\n' + data.error);
			}
		});
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

	var perlCheckerWidgets = [];

	var podCheck = function() {
		var editor = GetCurrentEditor();
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
		GetCurrentEditor().focus();
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
	
	$(document).on('action-new-file', function() {
		AddEditorTab();
	});

});