
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
		readOnly: true
	});

	// Some friendly advice
	diffEditor.setValue("This will contain commit changes.\nPlease use Git Diff to show something useful");
	
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

	$('a[href="#diff-tab"]').click(function() { 
		setTimeout(function() {
			diffEditor.refresh();
		}, 0);
	});

	var messages = [];

	window.sendMessage = function(action, params, callback) {
		var message = {
			action   : action,
			params   : params,
			callback : callback
		};
		console.info('sendMessage(' + action + ", ...)");
		messages.push(message);
		ws.send(JSON.stringify(message));
	};

	//--- Websockets support
	if("WebSocket" in window) {
		// WebSockets is supported
		console.info("websockets supported");


		// Bug workaround: Firefox escape key kills the websocket connection...
		if(navigator.userAgent.indexOf("Firefox") != -1) {
			$(window).keydown(function(e) {
				// Check for escape key
				if (e.which == 27) {
					// The following seems to fix the symptom but only in case the document has the focus
					e.preventDefault();
				}
			});	
		}

		var firstTime = true;
		var connectWebSocket = function() {
			// Connect
			window.ws = new WebSocket('ws://' + window.location.host + '/websocket');

			// Called once when the websocket connection is opened
			ws.onopen = function () { 
				// Change connection status to connected green
				$("#connection-status")
					.text("Connected")
					.addClass("btn-success")
					.removeClass("btn-danger");
	
				if(firstTime) {
					// Add an empty one editor tab on startup
					AddEditorTab();
					firstTime = false;
					
					// Set diff editor mode
					window.ChangeMode(diffEditor, 'diff');
				}
			};

			// Called when the websocket message arrives
			ws.onmessage = function(e) {
				var message = messages.pop();
				if(message.callback) {
					var data = JSON.parse(e.data);
					message.callback(data);
				}
			};

			// Called once when the websocket connection is closed
			ws.onclose = function(e) {

				// Change connection status to closed red
				$("#connection-status")
					.text("Closed")
					.addClass("btn-danger")
					.removeClass("btn-success");
				
				// Cleanup old websocket connection
				if(window.ws) {
					window.ws.close();
				}

				// Reconnect...
				setTimeout(connectWebSocket, 500);
			};
		};

		// Connect websocket connection
		connectWebSocket();

	} else {
		// No WebSockets support
		alert("WebSockets is not supported here!\nBrowser: " + navigator.userAgent);

		// Change connection status to unsupported red
		$("#connection-status")
			.text("Unsupported")
			.addClass("btn-danger")
			.removeClass("btn-success");
	}
	//--- Websockets support

	

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
			autoCloseBrackets: true,
			styleActiveLine: true,
			flattenSpans: false,
			extraKeys: {
				"F1": function(cm) {
					displayHelp(cm);
				},
				'Alt-A': function(cm) {
					$(".actions-button").click();
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
		editor.on("change", function(cm) {
				clearInterval(timeoutId);
				timeoutId = setTimeout(function() {
					var mode = cm.getOption("mode");
					if (mode == "perl") {
						syntaxCheck(cm);
					} else if (mode == "javascript") { 
						$(document).trigger('action-jshint');
					} else {
						$("#pod").html('Only supported for Perl files');
					}

				}, 250);

				showStarAfterNameIfModified(cm);
		});

		
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
			} else if (mode == "javascript") { 
				$(document).trigger('action-jshint');
			} else {
				$("#pod").html('Not supported for mode "' + mode + '"');
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
	
	function _displayHelp(topic, bShowDialog) {
		window.sendMessage('help_search', {"topic": topic}, function(results) {
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

	var podChanged = function(editor) {
		window.sendMessage('pod2html', {"source": editor.getValue()}, function(html) {
			$('#pod').html(html);
		});
	};

	$('a[href="#pod-tab"]').click(function() { 
		podChanged(GetCurrentEditor());
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
		window.sendMessage('perl-tidy', {"source": source}, function(data) {
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
		window.sendMessage('syntax-check', {"source": editor.getValue()}, function(problems) {
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

	$(document).on('action-syntax-check', function() {
		syntaxCheck(GetCurrentEditor());
	});

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
				url: 'assets/jshint/jshint-1.0.0.js',
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

	$(".topic").typeahead({
		source : function(query, process) {
			window.sendMessage('/typeahead', {'query': query}, function(matches) {
				process(matches);
			});
		}
	}).change(function() {
		_displayHelp($(this).val(), true);
	});
	
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
		window.sendMessage('save-file', {"filename": filename, "source": editor.getValue()}, function(data) {
			if(data.err === '') {
				editor.markClean();
				showStarAfterNameIfModified(editor);
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

		sendMessage('dump-ppi-tree', {"source": source}, function(data) {

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
	
	$(document).on('action-debug-step-in', function() {
		alert("Not implemented yet");
	});

	$(document).on('action-debug-step-over', function() {
		alert("Not implemented yet");
	});
	
	$(document).on('action-debug-step-out', function() {
		alert("Not implemented yet");
	});

	$(document).on('action-debug-stop', function() {
		alert("Not implemented yet");
	});

	$(document).on('action-git-diff', function() {
		window.sendMessage('git-diff', {}, function(result) {

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
	});

	$(document).on('action-perl-strip', function() {
		var editor = GetCurrentEditor();
		window.sendMessage('perl-strip', {source: editor.getValue()}, function(result) {
			if(result.error) {
				editor.setValue(result.source);
			} else {
				alert("No result");
			}
		});
	});

});
