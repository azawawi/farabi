/**
 * REPL - Read-Eval-Read-Loop  dialog 
 *
 * TODO document REPL dialog 
 */
$(function() {
	
	var $replDialog = $("#repl-dialog");

	$(document).on('action-repl', function() {
		$replDialog.modal('show');
		$("#command", $replDialog).focus();
	});

	var evalCommand = function() {
		$.ajax({
			type:    "POST",
			url:     "/repl-eval",
			data:    { 
				"command"    : $("#command", $replDialog).val(),
				"runtime" : $("#runtime :selected", $replDialog).attr("id"),
			},
			success: function(result) {
				var oldOutput = $("#output", $replDialog).val();
				if(result.err != '') {
					result.out += "\nError: " + result.err;
				}
				
				var $output = $("#output", $replDialog);
				$output.val(oldOutput + result.out);
				$("#command", $replDialog).val('');
				
				// Scroll output to bottom
				$output.scrollTop( $output[0].scrollHeight - $output.height() );
			},
			error:   function(jqXHR, textStatus, errorThrown) {
				console.error("Error!" + textStatus + ", " + errorThrown);
			}
		});

	};
	
	$("#run-button", $replDialog).click(function() {
		evalCommand();
	});
	
});