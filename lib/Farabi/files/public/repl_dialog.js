/**
 * REPL - Read-Eval-Read-Loop  dialog 
 *
 * TODO document REPL dialog 
 */
$(function() {
	
	var $replDialog = $("#repl-dialog");

	$(document).on('action-repl', function() {
		$replDialog.modal('show');
		$replDialog.on("shown", function() {
			$("#command", $replDialog).focus();
		});
	});

	var evalCommand = function() {
		$.post("/repl_eval", { 
				"command"    : $("#command", $replDialog).val(),
				"runtime" : $("#runtime :selected", $replDialog).attr("id")
			},
			function(result) {
				var oldOutput = $("#output", $replDialog).val();
				if(result.err !== '') {
					result.out += "\nError: " + result.err;
				}
				
				var $output = $("#output", $replDialog);
				$output.val(oldOutput + result.out);
				$("#command", $replDialog).val('');
				
				// Scroll output to bottom
				$output.scrollTop( $output[0].scrollHeight - $output.height() );
			}
		);
	};
	
	$("#run-button", $replDialog).click(function() {
		evalCommand();
	});
	
});