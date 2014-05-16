/**
 * Find duplicate Perl code dialog
 */
$(function() {

	var $dialog    = $("#duplicate-perl-code-dialog");

	// Handle OK Button clicks
	$("#ok-button", $dialog).click(function() {
		// Get the action name
		var dirs = $("#dirs", $dialog).val();
		
		// Find duplicate Perl code via Code::CutNPaste
		$.post("/code_cutnpaste", { "dirs": dirs }, function(result) {
			if(result.error === '') {
				if(result.count > 0) {
					// Show it in the output pane
					$("#output").val(result.output);
				} else {
					$("#output").val("No duplicate code found");
				}
			} else {
				$("#output").val(result.error);
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
	$(document).on('action-code-cutnpaste', function() {
		$dialog.modal('show');
		$dialog.on('shown', function() {
			$("#dirs").val('lib').focus();
		});
	});
	
});