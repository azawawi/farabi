/**
 * Find duplicate Perl code dialog
 */
$(function() {

	var $dialog    = $("#duplicate-perl-code-dialog");

	// Handle OK Button clicks
	$("#ok-button", $dialog).click(function() {
		// Get the action name
		var dirs = $("#dirs", $dialog).val();

		// Submit a POST request to find action
		$.ajax({
			type:    "POST",
			url:     "/find-duplicate-perl-code",
			data:    { "dirs": dirs },
			success: function(result) {

				if(result.count > 0) {
					// Show it in the output pane
					$("#output").val(result.output);
				} else {
					$("#output").val("No duplicate code found");
				}

			},
			error:   function(jqXHR, textStatus, errorThrown) {
				console.error("Error:\n" + textStatus + "\n" + errorThrown);
			}
		});
	});

	// Dialog global key up handler
	$dialog.keyup(function(e) {
		if(e.keyCode == 13) {
			// ENTER triggers an action
			$("#ok-button", $dialog).click();
		}
	});

	// Open the find duplicate perl dialog when the action is triggered
	$(document).on('action-find-duplicate-perl-code', function() {
		$dialog.modal('show');
		$dialog.on('shown', function() {
			$("#dirs").val('lib').focus();
		});
	});
	
});