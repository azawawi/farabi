/**
 * Goto line dialog
 */
$(function() {
	var $dialog    = $("#goto-line-dialog");

	// Called the goto line action is triggered
	$(document).on('action-goto-line', function() {

		// Open the dialog
		$dialog.modal('show');

		// Called when the dialog is shown
		$dialog.on('shown', function() {
			$("#line", $dialog).val('').focus();
		});

	});

	// Handle ENTER key
	$("#line", $dialog).keyup(function(e) {
		if(e.keyCode == 13) {
			// Goto line
			$("#ok-button", $dialog).click();
		}
	});
	
	// Called when the OK button is clicked
	$("#ok-button", $dialog).click(function() {

		if($(this).is(':disabled')) {
			// Do nothing if the button is disabled
			return;
		}

		var line = parseInt($("#line", $dialog).val(), 10);
		if(!isNaN(line)) {
			GetCurrentEditor().setCursor({line: line - 1, ch: 0});
		}

	});

});