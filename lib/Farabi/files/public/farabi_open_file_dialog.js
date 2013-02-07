/**
 * Open file dialog
 *
 * TODO document open file dialog
 */
$(function() {
	var $openFileDialog    = $("#open-file-dialog");

	var findFile = function() {
		var filename = $("#file", $openFileDialog).val();
		$("#matched-files", $openFileDialog).empty();
		$("#ok-button", $openFileDialog).attr("disabled","disabled");
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
			$("#ok-button", $openFileDialog).removeAttr("disabled");
			$("#matched-files", $openFileDialog).html(html);
		});
	}

	$(document).on('action-open-file', function() {
		$openFileDialog.modal('show');
		$openFileDialog.on('shown', function() {
			$("#file", $openFileDialog).val('').focus();
			$("#matched-files", $openFileDialog).empty();
			$("#ok-button", $openFileDialog).attr("disabled","disabled");
			findFile();
		});
	});

	$("#file", $openFileDialog).on('input', function() {
		findFile();
	});

	$("#file", $openFileDialog).keyup(function(e) {
		var keyCode = e.keyCode;
		if(keyCode == 40) {
			$("#matched-files", $openFileDialog).focus();
		} else if(keyCode == 13) {
			// Open selected file(s)
			$("#ok-button", $openFileDialog).click();
		}
	});

	// Handle double click event on the matched files list as an action trigger
	$("#matched-files", $openFileDialog).dblclick(function() {
		$("#ok-button", $openFileDialog).click();
	});
	
	if(navigator.userAgent.indexOf("Firefox") != -1) {
		// Firefox-specfic bug: Enter resets multiple selection to currently selected
		$("#matched-files", $openFileDialog).keypress(function(e) {
			if(e.keyCode == 13) {
				// Open selected file(s)
				$("#ok-button", $openFileDialog).click();
			}
		});
	} else {
		// Non-firefox browsers
		$("#matched-files", $openFileDialog).keyup(function(e) {
			if(e.keyCode == 13) {
				// Open selected file(s)
				$("#ok-button", $openFileDialog).click();
			}
		});
	}
	
	$("#ok-button", $openFileDialog).click(function() {

		if($(this).is(':disabled')) {
			// Button is disabled...
			return;
		}

		// Open selected file(s)
		$("#matched-files option:selected", $openFileDialog).each(function(key, value) { 
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