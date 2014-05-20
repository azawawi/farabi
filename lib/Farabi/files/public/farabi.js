
// Start Farabi when the document loads
$(function() {

	// Trigger actions dialog outside editor focus
	$(document).keydown(function(e) {
		if(e.altKey && e.keyCode == 65) { 
			// Trigger actions dialog
			$(".actions-button").click();
			
			// Prevent default text selection on Firefox
			e.preventDefault();
		}
	});
	

	var showHelp = function(cm, showDocTab) {
		var selection = cm.getSelection();
		var topic;
		if(selection) {
			topic = selection;
		} else {
			// Get cursor
			var cursor = cm.getCursor();

			//WORKAROUND: Resolve getTokenAt bug by adding 1 to column
			var c = {
				line: cursor.line,
				ch: cursor.ch + 1
			};
			
			// Search for token under the cursor
			var token = cm.getTokenAt(c);
			if(token.string) {
				topic = $.trim(token.string);
			} else {
				topic = '';
			}
		}
		
		$.post("/help", {
			topic  : topic, 
			style : $("#pod_style_selector", $('#options-dialog')).val()
			}, 
			function(html) {
				// Populate documentation tab
				var $iframe = $("#doc");
				var scrollTop = $iframe.contents().scrollTop();
				var doc = $iframe[0].contentDocument;
				doc.open();
				doc.write(html);
				doc.close();
				$iframe.contents().scrollTop(scrollTop);

				if(showDocTab) {
					// Show documentation tab
					$('a[href="#doc-tab"]').click();
				}
			}
		);
	};


	// Editors hash object
	var editors = {};

	// Current Editor
	var currentEditorId;

	// How many problems do we have for the current editor
	var problemCount = 0;

	// Cache dialog jQuery references for later use
	var $helpDialog = $("#help-dialog");
	var $perlDocDialog = $("#perl-doc-dialog");

	window.whitespaceOverlay = {
		showTabs   : false,
		showSpaces : false,
		token      : function(stream) {

			if (stream.eatWhile(/\S/)) {
				//Eat all non-whitespace tokens with no whitespace highlighting
				return null;
			}

			// Consume the whitespace character
			ch = stream.next();

			// And give it the proper CSS class
			if(ch == '\t') {
				return this.showTabs ? "whitespace-tab" : null;
			} else {
				return this.showSpaces ? "whitespace-space" : null;
			}
		}
	};

	window.showWhitespace = function(editor) {
		whitespaceOverlay.showSpaces = $("#show_spaces_checkbox").is(':checked');
		whitespaceOverlay.showTabs = $("#show_tabs_checkbox").is(':checked');
		
		// Refresh...
		editor.removeOverlay(window.whitespaceOverlay);
		editor.addOverlay(window.whitespaceOverlay);
		diffEditor.removeOverlay(window.whitespaceOverlay);
		diffEditor.addOverlay(window.whitespaceOverlay);
	};

	// Create the readonly CodeMirror input editor instance
	var inputEditor = CodeMirror.fromTextArea(document.getElementById('input'), {
		//TODO these should be configurable!
		tabSize: 4,
		indentUnit: 4,
		indentWithTabs: true
	});

	// Some friendly advice
	inputEditor.setValue("The following input will be sent to the process that is run");

	// Create the readonly CodeMirror output editor instance
	var outputEditor = CodeMirror.fromTextArea(document.getElementById('output'), {
		//TODO these should be configurable!
		tabSize: 4,
		indentUnit: 4,
		indentWithTabs: true,
		readOnly: true
	});

	outputEditor.setValue("Output from running processes is shown here.\nPlease run a script to show something useful");

	var diffEditor = CodeMirror.fromTextArea(document.getElementById('diff'), {
		//TODO these should be configurable!
		tabSize: 4,
		indentUnit: 4,
		indentWithTabs: true,
		readOnly: true,
		flattenSpans: false
	});

	// Some friendly advice
	diffEditor.setValue("This will contain commit changes.\nPlease use Git Diff to show something useful");

	// Create the readonly CodeMirror search editor instance
	var searchEditor = CodeMirror.fromTextArea(document.getElementById('search'), {
		//TODO these should be configurable!
		tabSize: 4,
		indentUnit: 4,
		indentWithTabs: true,
		readOnly: true
	});

	$('a[href="#input-tab"]').click(function() { 
		setTimeout(function() {
			inputEditor.refresh();
		}, 0);
		
	});

	$('a[href="#output-tab"]').click(function() { 
		setTimeout(function() {
			outputEditor.refresh();
		}, 0);
	});

	$('a[href="#search-tab"]').click(function() { 
		setTimeout(function() {
			searchEditor.refresh();
		}, 0);
	});

	$('a[href="#diff-tab"]').click(function() { 
		$(document).trigger("action-git-diff");
		setTimeout(function() {
			diffEditor.refresh();
		}, 0);
	});


	var firstTime = true;

	setInterval(function() {
		$.post("/ping", {}, function() {
			// Green connection status
			$("#connection-status")
			.text("Connected")
			.addClass("btn-success")
			.removeClass("btn-danger");

			if(firstTime) {
				// Add an empty one editor tab on startup
				AddEditorTab();

				// Set diff editor mode
				window.ChangeMode(diffEditor, 'diff');

				firstTime = false;
			}
		}).fail(function() {
			// Red connection status
			$("#connection-status")
			.text("Closed")
			.addClass("btn-danger")
			.removeClass("btn-success");

		});
	}, 5000);
 

	// Show a '*' after the tab name if it is modified	
	var showStarAfterNameIfModified = function(editor) {
		if(editor.isClean()) {
			$("#myTab > li.active > a > span").text('');
		} else {
			$("#myTab > li.active > a > span").text(" *");
		}
	};


	var tabId = 1;
	window.AddEditorTab = function(tabName, filename, mode, contents) {
		
		if(!tabName) {
			// Tab name
			tabName = "Untitled " + tabId;
		}
		
		// Generate editor id
		var editorId = "editor" + tabId;

		// Add the tab component
		$("#myTab").append('<li><a href="#' + tabId + '" data-toggle="tab">' + tabName + '&nbsp;<span></span>&nbsp;&nbsp;<i class="icon-remove"></i></a></li>');
		
		// Add the new tab button
		$("#myTab li.farabi-add-tab").remove();
		$("#myTab").append('<li class="farabi-add-tab">&nbsp;<i class="icon-plus-sign"></i></li>');
		
		// When add file is clicked, new file action is trigger
		$(".farabi-add-tab").click(function() {
			$(document).trigger('action-new-file');
		});

		// Add the tab editor
		$("#myTabContent").append(
			'<div class="tab-pane" id="' + tabId + '">' +
				'<div class="farabi-bordered" id="editor-border">' +
					'<textarea id="'+editorId+'" name="' + editorId +'" class="editor"></textarea>' +
					'<div class="editor-stats pull-right"></div>' +
				'</div>' +
			'</div>');
			
		$("i", "#myTab").mouseover(function() {
			$(this).addClass("farabi-icon-selected");
		});
		
		$("i", "#myTab").mouseout(function() {
			$(this).removeClass("farabi-icon-selected");
		});
		
		// When the close file icon is clicked
		$("i.icon-remove", "#myTab").click(function(e) {
			
			// Update currentEditorId
			var $tab = $(this).parent();
			var href = $tab.attr("href");
			currentEditorId = "editor" + href.substring(1);
			
			currentEditor = editors[currentEditorId].editor;

			// Stop event propagation right away
			e.stopImmediatePropagation();

			// Trigger close file action
			$(document).trigger('action-close-file');

		});

		var show_cmd_output = function(data) {
			var outputEditor = GetOutputEditor();
			outputEditor.setValue('');

			if(typeof data.stderr == "undefined") {
				// Websocket messages are not synchronized... workaround for now
				outputEditor.setValue("Invalid response.. Please run it again. Hopefully will fix it soon :)");

				// Show output tab
				$('a[href="#output-tab"]').tab('show');

				setTimeout(function() {
					outputEditor.refresh();
				}, 0);

				return;
			}

			if (data.stderr && data.stderr.length) {
				// Handle STDERR
				outputEditor.setValue(data.stderr + "\n");
			}

			// Handle STDOUT
			outputEditor.setValue(outputEditor.getValue() + data.stdout + "\nExit code: " + data.exit);

			// Show output tab
			$('a[href="#output-tab"]').tab('show');

			setTimeout(function() {
				outputEditor.refresh();
			}, 0);
		};

		// Create the CodeMirror editor instance
		var editor = CodeMirror.fromTextArea(document.getElementById(editorId), {
			//TODO these should be configurable!
			lineNumbers: true,
			matchBrackets: true,
			tabSize: 4,
			indentUnit: 4,
			indentWithTabs: true,
			highlightSelectionMatches: true,
			styleSelectedText: true,
			styleActiveLine: true,
			flattenSpans: false,
			extraKeys: {
				"F1": function(cm) {
					showHelp(cm, true);
				},
				'Ctrl-Alt-F': function(cm) {
					$(document).trigger('action-ack');
				},
				'Alt-A': function(cm) {
					$(".actions-button").click();
				},
				'Alt-N': function(cm) {
					$(document).trigger('action-new-file');
				},
				'Alt-O': function(cm) {
					$(document).trigger('action-open-file');
				},
				'Alt-S': function(cm) {
					$(document).trigger('action-save-file');
				},
				'Alt-W': function(cm) {
					$(document).trigger('action-close-file');
				},
				"Alt-L": function(cm) {
					$(document).trigger('action-goto-line');
				},
				'Alt-Enter': function(cm) {
					// TODO make it more generic and we need runtime profiles
					var mode = cm.getOption("mode");
					if(mode == "perl") {
						$.post(
							'run_perl',
							{
								"source": cm.getValue(),
								"input": GetInputEditor().getValue()
							},
							function(result) {
								show_cmd_output(result);
							}
						);
					} else {
						$("#action-run").click();
					}
				},
				"F10": function(cm) {
					// F11 does not work on linux for some reason!
					cm.setOption("fullScreen", !cm.getOption("fullScreen"));
				},
				"F11": function(cm) {
					cm.setOption("fullScreen", !cm.getOption("fullScreen"));
				},
				"Esc": function(cm) {
					if (cm.getOption("fullScreen")) {
						cm.setOption("fullScreen", false);
					}
				}
			}
		});
		
		// Set the contents if available
		if(contents) {
			editor.setValue(contents);
			editor.clearHistory();
			editor.markClean();
		}

		// Change the mode...
		if( !mode ) {
			// Default to Perl language
			window.ChangeMode(editor, 'perl');
		} else {
			window.ChangeMode(editor, mode);
		}

		// Hook up with cursor activity event
		editor.on("cursorActivity", function(cm) {
				// Show editor statistics
				window.showEditorStats(cm);
		});

		// Hook up with change event
		var timeoutId;
		var onChange = function(cm) {
				clearInterval(timeoutId);
				timeoutId = setTimeout(function() {
					var mode = cm.getOption("mode");
					if (mode == "perl") {
						syntaxCheck(cm);

						if($("#preview-tab").is(":visible")) {
							$('a[href="#preview-tab"]').click();
						}

					} else if(mode == "markdown") {
						if($("#preview-tab").is(":visible")) {
							$('a[href="#preview-tab"]').click();
						}
					} else if (mode == "javascript") { 
						$(document).trigger('action-jshint');
					} else {
						$("#pod").html('Only supported for Perl files');
					}

				}, 250);

				showStarAfterNameIfModified(cm);
		};
		
		editor.on("change", onChange);
		editor.on("focus", onChange);

		
		// Store editor reference
		editors[editorId] = {
			editor   : editor,
			filename : filename,
			tabName  : tabName,
			tabId    : tabId
		};
		
		// This is the current editor identifier
		currentEditorId = editorId;

		// Show the last editor tab which we added
		var $lastTab = $("#myTab a:last");
		$lastTab.tab('show');
		
		// And refresh the editor once it is shown
		$lastTab.on('shown', function (e) {
			editor.refresh();
		});

		// When a tab is shown, let us update current editor id
		$("#myTab a").on('shown', function() {
			// Update currentEditorId
			currentEditorId = "editor" + $(this).attr("href").substring(1);
		});

		// Run these when we exit this one
		setTimeout(function() {
			// focus!
			editor.focus();

			// Show editor stats at startup
			window.showEditorStats(editor);

			// Trigger theme selection
			$("#theme_selector").change();

			var mode = editor.getOption("mode");
			if(mode == "perl") {
				// Run syntax check at startup
				syntaxCheck(editor);

				// Update preview tab if it is visible
				if($("#preview-tab").is(":visible")) {
					$('a[href="#preview-tab"]').click();
				}

			} else if(mode == "markdown") {
				if($("#preview-tab").is(":visible")) {
					$('a[href="#preview-tab"]').click();
				}
			} else if (mode == "javascript") { 
				$(document).trigger('action-jshint');
			} else {
				$("#pod").html('Not supported for mode "' + mode + '"');
			}

			// Update changes tab if it is visible
			if($("#diff-tab").is(":visible")) {
				$(document).trigger("action-git-diff");
			}

			window.showWhitespace(editor);

			editor.refresh();

		}, 0);

		tabId++;
	};
	

	// Disable all form submission to prevent UI from refreshing by mistake on ENTER
	$("form").submit(function() {
		return false;
	});
	
	window.ChangeMode = function(cm, modeFile, mode) {
		if(typeof mode == 'undefined') {
			mode = modeFile;
		}
		CodeMirror.modeURL = "assets/codemirror/mode/%N/%N.js";
		cm.setOption("mode", mode);
		CodeMirror.autoLoadMode(cm, modeFile);	
	};

	window.showEditorStats = function(cm) {

		var cursor = cm.getCursor();
		var selection = cm.getSelection();
		var line_number = cursor.line + 1;
		var column_number = cursor.ch + 1;
		
		var $editorStats = $('.editor-stats');
		$editorStats.html(
			'<span class="badge badge-info"><strong>Line: ' + line_number + '</strong></span>' +
			'&nbsp;<span class="badge badge-info"><strong>Column: ' + column_number + '</strong></span>' +
			'&nbsp;<span class="badge badge-info"><strong>Lines: ' + cm.lineCount() + '</strong></span>' +
			(selection ?  '&nbsp;<span class="badge badge-info"><strong>Selected: ' + selection.length +'</strong></span>' : '')  +
			'&nbsp;<span class="badge badge-info"><strong>Characters: ' + cm.getValue().length + '</strong></span>&nbsp;' +
				((problemCount > 0) ? '<span id="problems-button" class="badge badge-important"><strong>Problems: ' + problemCount + '</strong></span>' : '<span id="problems-button" class="badge badge-success"><strong>No Problems</span>')
		);

		$("#problems-button", $editorStats).click(function() {
			$('a[href="#problems-tab"]').tab('show');
		});
	};

	var previewTabChanged = function(editor) {
		var mode = editor.getOption("mode");
		if(mode == "perl") {
			$.post("/pod2html", 
				{
					"source": editor.getValue(),
					"style": $("#pod_style_selector", $('#options-dialog')).val()
				},function(html) {
					var $iframe = $("#pod");
					var scrollTop = $iframe.contents().scrollTop();
					var doc = $iframe[0].contentDocument;
					doc.open();
					doc.write(html);
					doc.close();
					$iframe.contents().scrollTop(scrollTop);
				}
			);
		} else if(mode == "markdown") {
			$.post("/md2html", 
				{
					"text": editor.getValue()
				},function(html) {
					var $iframe = $("#pod");
					var scrollTop = $iframe.contents().scrollTop();
					var doc = $iframe[0].contentDocument;
					doc.open();
					doc.write(html);
					doc.close();
					$iframe.contents().scrollTop(scrollTop);
				}
			);
		}
	};

	$('a[href="#preview-tab"]').click(function() { 
		previewTabChanged(GetCurrentEditor());
	});

	// Get the current editor
	window.GetCurrentEditor = function() {
		return editors[currentEditorId].editor;
	};

	// Returns the current editor filename
	window.GetCurrentFilename = function() {
		return editors[currentEditorId].filename;
	};

	window.GetOutputEditor = function() {
		return outputEditor;
	};

	window.GetInputEditor = function() {
		return inputEditor;
	};

	window.GetSearchEditor = function() {
		return searchEditor;
	};

	window.GetEditors = function() {
		var results = [];
		for(var editorId in editors) {
			results.push(editors[editorId].editor);
		}
		return results;
	};

	$(".results").hide();

	$(document).on('action-perl-doc', function() {
		$perlDocDialog.modal('show');
	});

	$(document).on('action-perl-tidy', function() {
		var editor = GetCurrentEditor();
		var outputEditor = GetOutputEditor();
		var source = editor.getValue();
		$.post('perl_tidy', {"source": source}, function(data) {
			if(data.error === '') {

				if(source != data.source) {

					// Save current cursor position
					var cursor = editor.getCursor();

					// Set tidied text to editor
					editor.setValue(data.source);

					// Restore old cursor position
					editor.setCursor(cursor);
				}

			} else {
				outputEditor.setValue('Error:\n' + data.error);
			}
		});
	});

	var syntaxCheckerWidgets = [];
	var syntaxCheck = function(editor) {
		$.post('/syntax_check', {"source": editor.getValue()}, function(problems) {
			editor.operation(function(){
				var i;
				for (i = 0; i < syntaxCheckerWidgets.length; i++) {
					editor.removeLineWidget(syntaxCheckerWidgets[i]);
				}
				syntaxCheckerWidgets.length = 0;

				//TODO temporary solution until we can figure out how to cooperate
				$(".farabi-error-icon").remove();

				problemCount = problems.length;

				var html = '';

				if(problems.length > 0) {

					html += "<thead>" +
						"<th>Line</th>" +
						"<th>Message</th>" +
						"<th>File</th>" +
						"<th>Source</th>" +
						"</thead>";
					html += "<tbody>";

					var showProblemsTab = function() {
						$('a[href="#problems-tab"]').tab('show');
					};

					for(i = 0; i < problems.length; i++) {
						var problem = problems[i];

						// Add warning or error under the editor line
						var msg = document.createElement("div");
						var icon = msg.appendChild(document.createElement("span"));
						icon.innerHTML = "!!";
						icon.className = "farabi-error-icon";
						msg.appendChild(document.createTextNode(problem.message));
						msg.className = "farabi-error";

						syntaxCheckerWidgets.push(
							editor.addLineWidget(
								problem.line - 1,
								msg, 
								{coverGutter: true, noHScroll: true}
							)
						);

						$(msg).click(showProblemsTab);

						html += 
							"<tr>" +
								'<td class="problem-line">' + problem.line + "</td>" +
								"<td>" + problem.message + "</td>" +
								"<td>" + problem.file + "</td>" +
								"<td>Syntax Check</td>" +
							"</tr>";
					}

					html += "</tbody>";
				} else {
					html = '<tr>' +
						'<td><span class="badge badge-success">No problems found</span></td>' +
						'</tr>';
				}

				$("#problems > table").html(html);
				$("#problems>  table > tbody > tr").click(function() { 
					var line = parseInt($(".problem-line", this).text(), 10);
					var editor = GetCurrentEditor();
					editor.setCursor({line: line - 1, ch: 0});
				});

				// Update editor statistics
				window.showEditorStats(editor);
			});

		});
	};

	// JSHint: JavaScript static code analysis
	var jsHintWidgets = [];
	var jsHint = function(editor) {
		editor.operation(function(){
			var i;
			for (i = 0; i < jsHintWidgets.length; i++) {
				editor.removeLineWidget(jsHintWidgets[i]);
			}
			jsHintWidgets.length = 0;

			//TODO temporary solution until we can figure out how to cooperate
			$(".farabi-error-icon").remove();

			JSHINT(editor.getValue());
			problemCount = JSHINT.errors.length;

			var html = '';
			if(JSHINT.errors.length > 0) {
				
				html += 
					"<thead>" +
						"<th>Line</th>" +
						"<th>Message</th>" +
						"<th>File</th>" +
						"<th>Source</th>" +
					"</thead>";
				html += "<tbody>";

				var showProblemsTab = function() {
					$('a[href="#problems-tab"]').tab('show');
				};

				for (i = 0; i < JSHINT.errors.length; ++i) {
					var problem = JSHINT.errors[i];
					if (!problem) {
						continue;
					}

					// Add warning or error under the editor line
					var msg = document.createElement("div");
					var icon = msg.appendChild(document.createElement("span"));
					icon.innerHTML = "!!";
					icon.className = "farabi-error-icon";
					msg.appendChild(document.createTextNode(problem.reason));
					msg.className = "farabi-error";

					jsHintWidgets.push(
						editor.addLineWidget(
							problem.line - 1,
							msg, 
							{coverGutter: true, noHScroll: true}
						)
					);

					$(msg).click(showProblemsTab);

					html += 
						"<tr>" +
							'<td class="problem-line">' + problem.line + "</td>" +
							"<td>" + problem.reason + "</td>" +
							"<td></td>" +
							"<td>JSHint</td>" +
						"</tr>";
				}

				html += "</tbody>";
			} else {
				html = '<tr>' +
					'<td><span class="badge badge-success">No problems found</span></td>' +
						'</tr>';
			}
			
			$("#problems > table").html(html);
			$("#problems>  table > tbody > tr").click(function() { 
				var line = parseInt($(".problem-line", this).text(), 10);
				var editor = GetCurrentEditor();
				editor.setCursor({line: line - 1, ch: 0});
			});

			// Update editor statistics
			window.showEditorStats(editor);

		});
	};

	$(document).on('action-jshint', function() {

		// JSHint
		var editor = GetCurrentEditor();
		if("JSHint" in window) {

			jsHint(editor);

		} else {

			// Load JSHint and then run
			$.ajax({
				url: 'assets/jshint/jshint-1.1.0.js',
				dataType: "script",
				success: function() {
					jsHint(editor);
				}
			});

		}

	});

	$(document).on('action-help', function() {
		$helpDialog.modal("show");
	});

	var onCloseFocusEditor = function () {
		var editor = GetCurrentEditor();
		if(editor) {
			editor.focus();
		}
	};

	// All modal dialogs are now hidden on startup
	// And when hidden event is trigged, the focus is changed
	// to the current editor
	$(".modal").hide().on('hidden', onCloseFocusEditor);

	$(document).on('action-new-file', function() {
		AddEditorTab();
	});

	$(".navbar .dropdown-menu li > a").click(function() {
		var action = $(this).attr("id");
		if(action) {
			$(document).trigger(action);
		} else {
			alert("Undefined action. Please specify it as an id attribute!");
		}
	});

	
	$(document).on('action-close-file', function() {
		
		var o = editors[currentEditorId];
		if(!o.editor.isClean()) {
			// Can it be safely close file without losing data?
			$("#save-question-dialog").modal('show');
			return;
		}

		// Utility function to find if the object is empty or not
		var isEmpty = function (obj) {
			for (var key in obj) {
				return false;
			}
			return true;
		};
		
		// Remove the current tab from the UI
		var currentTabId = editors[currentEditorId].tabId;
		$("#myTab > li > a[href=#" + currentTabId + "]").remove();
		$("#myTabContent > div[id=" + currentTabId + "]").remove();

		// Remove it from editors object
		delete editors[currentEditorId];
		
		if(isEmpty(editors)) {
			// Add a default tab if it was the last tab
			AddEditorTab();
		} else {
			// Find the last tab
			var $lastTab = $("#myTab a:last");
			
			// Show the last editor tab which we added
			$lastTab.tab('show');

			// Update currentEditorId
			currentEditorId = "editor" + $lastTab.attr("href").substring(1);

			GetCurrentEditor().focus();
		}
	});

	// Handle the close all files action
	$(document).on('action-close-all-files', function() {
		$("#myTab > li").remove();
		$("#myTabContent > div").remove();

		// Empty all editors
		editors = {};

		// Add a default tab since there is none
		AddEditorTab();
	});

	// Handle the save file action
	$(document).on('action-save-file', function() {
		var editor = GetCurrentEditor();
		var filename = GetCurrentFilename();
		$.post('/save_file', {"filename": filename, "source": editor.getValue()}, function(data) {
			if(data.err === '') {
				editor.markClean();

				showStarAfterNameIfModified(editor);

				// Update changes tab if it is visible
				if($("#diff-tab").is(":visible")) {
					$(document).trigger("action-git-diff");
				}
			} else {
				alert('Error:\n' + data.err);
			}
		});
	});

	// Handle the dump ppi tree action
	$(document).on('action-dump-ppi-tree', function() {
		var editor = GetCurrentEditor();
		var outputEditor = GetOutputEditor();
		
		outputEditor.setValue("'" + editor.getSelection() + "'");

		// Get the editor selection and fallback to
		// all editor contents
		var source = editor.getSelection();
		if(source === '') {
			source = editor.getValue();
		}

		$.post('/dump_ppi_tree', {"source": source}, function(data) {

			if(data.error === '') {
				outputEditor.setValue(data.output);
			} else {
				outputEditor.setValue(data.error);
			}

			// Show output tab
			$('a[href="#output-tab"]').tab('show');

			outputEditor.refresh();
		});
	});

	$(".navbar .brand").click(function() {
		$(document).trigger("action-about");
	});
	

	var git = function(cmd) {
		$.post('/git', {cmd: cmd}, function(result) {

			diffEditor.setValue('');

			// Handle STDERR
			if (result.stderr.length) {
				diffEditor.setValue(result.stderr + "\n");
			}

			// Handle STDOUT
			diffEditor.setValue(diffEditor.getValue() + result.stdout);

			// Show diff tab
			$('a[href="#diff-tab"]').tab('show');

			diffEditor.refresh();
		});
	};

	$(document).on('action-git-diff', function() {
		git('diff');
	});

	$(document).on('action-git-log', function() {
		git('log');
	});

	$(document).on('action-git-status', function() {
		git('status');
	});

	$(document).on('action-perl-strip', function() {
		var editor = GetCurrentEditor();
		$.post('/perl_strip', {source: editor.getValue()}, function(result) {
			if(result.error) {
				editor.setValue(result.source);
			} else {
				alert("No result");
			}
		});
	});

	$(document).on('action-spellunker', function() {
		var editor = GetCurrentEditor();
		$.post('/spellunker', {text: editor.getValue()}, function(result) {
			spellunker(editor);
		});
	});

	// Spellunker: Awesome Spell checking in Pure Perl
	var spellunkerWidgets = [];
	var spellunker = function(editor) {
		$.post('/spellunker', {"text": editor.getValue()}, function(problems) {
			editor.operation(function(){
				var i;
				for (i = 0; i < spellunkerWidgets.length; i++) {
					editor.removeLineWidget(spellunkerWidgets[i]);
				}
				spellunkerWidgets.length = 0;

				//TODO temporary solution until we can figure out how to cooperate
				$(".farabi-error-icon").remove();

				problemCount = problems.length;

				var html = '';

				if(problems.length > 0) {

					html += "<thead>" +
						"<th>Line</th>" +
						"<th>Message</th>" +
						"<th>File</th>" +
						"<th>Source</th>" +
						"</thead>";
					html += "<tbody>";

					var showProblemsTab = function() {
						$('a[href="#problems-tab"]').tab('show');
					};

					for(i = 0; i < problems.length; i++) {
						var problem = problems[i];

						// Add warning or error under the editor line
						var msg = document.createElement("div");
						var icon = msg.appendChild(document.createElement("span"));
						icon.innerHTML = "!!";
						icon.className = "farabi-error-icon";
						msg.appendChild(document.createTextNode(problem.message));
						msg.className = "farabi-error";

						spellunkerWidgets.push(
							editor.addLineWidget(
								problem.line - 1,
								msg, 
								{coverGutter: true, noHScroll: true}
							)
						);

						$(msg).click(showProblemsTab);

						html += 
							"<tr>" +
								'<td class="problem-line">' + problem.line + "</td>" +
								"<td>" + problem.message + "</td>" +
								"<td>" + problem.file + "</td>" +
								"<td>Spellunker</td>" +
							"</tr>";
					}

					html += "</tbody>";
				} else {
					html = '<tr>' +
						'<td><span class="badge badge-success">No problems found</span></td>' +
						'</tr>';
				}

				$("#problems > table").html(html);
				$("#problems>  table > tbody > tr").click(function() { 
					var line = parseInt($(".problem-line", this).text(), 10);
					var editor = GetCurrentEditor();
					editor.setCursor({line: line - 1, ch: 0});
				});

				// Update editor statistics
				window.showEditorStats(editor);
			});

		});
	};


	$(document).on('action-ack', function() {
		var editor = GetCurrentEditor();
		var selection = editor.getSelection();
		if(!selection) {
			setTimeout(function() {
				alert("Please select some text to search for it in your current project folder");
			}, 0);
			return;
		}

		$.post('/ack', {text: selection}, function(result) {

			var searchEditor = GetSearchEditor();
	
			searchEditor.setValue('');

			// Handle STDERR
			if (result.stderr.length) {
				searchEditor.setValue(result.stderr + "\n");
			}

			// Handle STDOUT
			searchEditor.setValue(searchEditor.getValue() + result.stdout);

			// Show search tab
			$('a[href="#search-tab"]').tab('show');

			searchEditor.refresh();

		});
	});

	var showCmdOutput = function(result) {

		var outputEditor = GetOutputEditor();

		outputEditor.setValue('');

		// Handle STDERR
		if (result.stderr.length) {
			outputEditor.setValue(result.stderr + "\n");
		}

		// Handle STDOUT
		outputEditor.setValue(outputEditor.getValue() + result.stdout);

		// Show output tab
		$('a[href="#output-tab"]').tab('show');

		outputEditor.refresh();
	};

	$(document).on('action-midgen', function() {
		$.post('/midgen', {}, showCmdOutput);
	});

	$(document).on('action-build', function() {
		$.post('/project', {cmd: 'build'}, showCmdOutput);
	});

	$(document).on('action-build-test', function() {
		$.post('/project', {cmd: 'test'}, showCmdOutput);
	});

	$(document).on('action-build-clean', function() {
		$.post('/project', {cmd: 'clean'}, showCmdOutput);
	});

	$(document).on('action-cpanm', function() {
		var editor = GetCurrentEditor();
		var selection = editor.getSelection();
		if(!selection) {
			setTimeout(function() {
				alert("Please select some text to search for it in your current project folder");
			}, 0);
			return;
		}

		$.post('/cpanm', {module: selection}, showCmdOutput);
	});

});
