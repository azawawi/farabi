/**
 * New project dialog
 */
$(function() {
	var $dialog    = $("#new-project-dialog");

	// Called the new project action is triggered
	$(document).on('action-new-project', function() {
		// Open the dialog
		$dialog.modal('show');
		
		// Called when the dialog is shown
		$dialog.on('shown', function() {
			$("#distro", $dialog).focus();
			$("#ok-button", $dialog).attr("disabled","disabled");
			findFile();
		});
	});

	// Called when the OK button is clicked
	$("#ok-button", $dialog).click(function() {

		if($(this).is(':disabled')) {
			// Do nothing if the button is disabled
			return;
		}

		/*
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
		*/

	});

});