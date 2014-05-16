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

		alert("Not implemented unfortunately...");
	});

});