/**
 * Options Dialog
 * TODO document Options dialog
 */
$(function() {
	var $optionsDialog = $('#options-dialog');
	
	$(document).on('action-options', function() {
		$optionsDialog.modal('show');
		$("#mode_selector", $optionsDialog).focus();
	});
	
	$("#line_numbers_checkbox", $optionsDialog).change(function() {
		editor.setOption('lineNumbers', $(this).is(':checked'));
	});

	$("#pod_viewer_checkbox",$optionsDialog).change(function() {
		if ( $(this).is(':checked') ) {
			$("#pod-tab").addClass("span6").show();
			$("#editor-border").removeClass("span12").addClass("span6");
		} else {
			$("#pod-tab").removeClass("span6").hide();
			$("#editor-border").removeClass("span6").addClass("span12");
		}
	});

	$("#tab_size", $optionsDialog).change(function() {
		var tabSize = $(this).val();
		if($.isNumeric(tabSize)) {
			$(this).parent().parent().removeClass("error");
			editor.setOption('tabSize', tabSize);
		} else {
			$(this).parent().parent().addClass("error");
		}
	});

});