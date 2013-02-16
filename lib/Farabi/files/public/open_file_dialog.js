/**
 * Open file(s) dialog
 */
$(function() {
	var $dialog    = $("#open-files-dialog");

	// Find file
	var findFile = function() {
		var filename = $("#file", $dialog).val();
		$("#matched-files", $dialog).empty();
		$("#ok-button", $dialog).attr("disabled","disabled");
		
		// Send a websocket-based message to find this file
		window.sendMessage("find-file", { "filename": filename }, function(results) {
			// Build matched files HTML
			var html = '';
			for(var i = 0; i < results.length; i++) {
				var result = results[i];
				html += "<option id='" + result.id + "' "  + 
					((i === 0) ? "selected" : "") + 
					">" + 
					result.name + 
					"</option>";
			}

			// OK button is disabled for now
			$("#ok-button", $dialog).removeAttr("disabled");

			// Add matched files HTML
			$("#matched-files", $dialog).html(html);

			// On each selection change in the matched files list, display the corresponding path
			$("#matched-files", $dialog).change(function() {
				var html = [];
				$("#matched-files :selected", $dialog).each(function(key, value) {
					html.push($(value).attr("id"));
				});
				$("#path", $dialog).html(html.join("<br>"));
			});

			$("#matched-files :selected", $dialog).change();

		});
	};

	// Called the open files action is triggered
	$(document).on('action-open-file', function() {
		// Open the dialog
		$dialog.modal('show');
		
		// Called when the dialog is shown
		$dialog.on('shown', function() {
			$("#file", $dialog).val('').focus();
			$("#matched-files", $dialog).empty();
			$("#ok-button", $dialog).attr("disabled","disabled");
			findFile();
		});
	});

	// On each file text field input change find that file
	$("#file", $dialog).on('input', function() {
		findFile();
	});

	// Handle DOWN and ENTER
	$("#file", $dialog).keyup(function(e) {
		var keyCode = e.keyCode;
		if(keyCode == 40) {
			// Focus on the matched file list
			$("#matched-files", $dialog).focus();
		} else if(keyCode == 13) {
			// Open selected file(s)
			$("#ok-button", $dialog).click();
		}
	});

	// Handle double click event on the matched files list as an action trigger
	$("#matched-files", $dialog).dblclick(function() {
		$("#ok-button", $dialog).click();
	});
	
	if(navigator.userAgent.indexOf("Firefox") != -1) {
		// Firefox-specfic bug: Enter resets multiple selection to currently selected
		$("#matched-files", $dialog).keypress(function(e) {
			if(e.keyCode == 13) {
				// Open selected file(s)
				$("#ok-button", $dialog).click();
			}
		});
	} else {
		// Non-firefox browsers
		$("#matched-files", $dialog).keyup(function(e) {
			if(e.keyCode == 13) {
				// Open selected file(s)
				$("#ok-button", $dialog).click();
			}
		});
	}

	// Called when the OK button is clicked
	$("#ok-button", $dialog).click(function() {

		if($(this).is(':disabled')) {
			// Do nothing if the button is disabled
			return;
		}

		// Open selected file(s)
		$("#matched-files option:selected", $dialog).each(function(key, value) { 
			var filename = $(value).attr("id");

			if (filename.length === 0) {
				console.warn("file name is empty");
				return;
			}

			// Send an open-file websocket message
			window.sendMessage(
				"open-file", { "filename": filename }, function(result) {
					if(result.ok) {
						// Open the file in a new tab
						AddEditorTab(result.filename, filename, result.mode, result.value);
					} else {
						// Error
						alert(result.value);
					}
				}
			);
		});

	});

});