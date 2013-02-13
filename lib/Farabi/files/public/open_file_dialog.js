/**
 * Open file(s) dialog
 */
$(function() {
	var $dialog    = $("#open-files-dialog");

	var findFile = function() {
		var filename = $("#file", $dialog).val();
		$("#matched-files", $dialog).empty();
		$("#ok-button", $dialog).attr("disabled","disabled");
		window.sendMessage("find-file", { "filename": filename }, function(results) {
			var html = '';
			for(var i = 0; i < results.length; i++) {
				var result = results[i];
				html += "<option id='" + result.id + "' "  + 
					((i == 0) ? "selected" : "") + 
					">" + 
					result.name + 
					"</option>";
			}
			$("#ok-button", $dialog).removeAttr("disabled");
			$("#matched-files", $dialog).html(html);
		});
	}

	$(document).on('action-open-file', function() {
		$dialog.modal('show');
		$dialog.on('shown', function() {
			$("#file", $dialog).val('').focus();
			$("#matched-files", $dialog).empty();
			$("#ok-button", $dialog).attr("disabled","disabled");
			findFile();
		});
	});

	$("#file", $dialog).on('input', function() {
		findFile();
	});

	$("#file", $dialog).keyup(function(e) {
		var keyCode = e.keyCode;
		if(keyCode == 40) {
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
	
	$("#ok-button", $dialog).click(function() {

		if($(this).is(':disabled')) {
			// Button is disabled...
			return;
		}

		// Open selected file(s)
		$("#matched-files option:selected", $dialog).each(function(key, value) { 
			var filename = $(value).attr("id");

			if (filename.length == 0) {
				console.warn("file name is empty");
				return;
			}

			window.sendMessage(
				"open-file", { "filename": filename }, function(result) {
					if(result.ok) {
						AddEditorTab(result.filename, filename, result.mode, result.value);
					} else {
						alert(result.value);
					}
				}
			);
		});

	});

});