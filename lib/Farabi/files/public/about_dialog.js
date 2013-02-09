/**
 * About Dialog
 */
$(function() {

	// The cached about dialog jQuery reference
	var $dialog    = $("#about-dialog");

	// Update Perlito 5 version text
	var updatePerlito5Version = function() {
		$('#perlito5-version', $dialog).text(  p5pkg[ "main" ][ "v_]"]);
	};

	// Called when the about action is triggered
	$(document).on('action-about', function() {

		// Perlito 5 version
		if(typeof p5pkg == 'undefined') {
			// Perlito 5 needs to be loaded
			$.ajax({
				url: 'assets/perlito/perlito5.min.js',
				dataType: "script",
				cache: true,
				success: function() {
					updatePerlito5Version();
				}
			});
		} else {
			updatePerlito5Version();
		}

		// jQuery version
		$('#jquery-version', $dialog).text($().jquery);

		// CodeMirror version
		$('#codemirror-version', $dialog).text(CodeMirror.version);

		// Show the about dialog
		$dialog.modal("show");
	});


});