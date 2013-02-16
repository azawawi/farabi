/**
 * Goto line dialog
 */
$(function() {
	var $dialog    = $("#goto-line-dialog");
	var $okButton  = $("#ok-button", $dialog);

	$("#line", $dialog).val(1);

	// Called the goto line action is triggered
	$(document).on('action-goto-line', function() {

		// Open the dialog
		$dialog.modal('show');

		// Called when the dialog is shown
		$dialog.on('shown', function() {
			$("#line", $dialog).focus();
		});

	});

	// Handle ENTER key
	$("#line", $dialog).keyup(function(e) {

		if(e.keyCode == 13) {
			// Goto line
			$okButton.click();
			return;
		}

		var lineNumberText = $("#line", $dialog).val();
		var $helpInline = $(".help-inline", $dialog);
		if(lineNumberText.match(/^\d+$/)){
			$helpInline.html("");
			$helpInline.parent().parent().removeClass("error");
			$okButton.removeAttr("disabled");
		} else {
			$helpInline.html("Invalid line number");
			$helpInline.parent().parent().addClass("error");
			$okButton.attr("disabled", "disabled");
		}
	});
	
	// Called when the OK button is clicked
	$okButton.click(function(e) {

		if($(this).is(':disabled')) {
			// Do nothing if the button is disabled
			return;
		}

		var line = parseInt($("#line", $dialog).val(), 10);
		GetCurrentEditor().setCursor({line: line - 1, ch: 0});

	});

});