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
	
	$("#mode_selector", $optionsDialog).change(function() {
		var $selectedMode = $(":selected", this);
		var editor = GetCurrentEditor();
		var mode = $selectedMode.val();
		if(mode == 'clike') {
			ChangeMode(editor, mode, 'text/x-csrc');
		} else if(mode == 'plsql') {
			ChangeMode(editor, mode, 'text/x-plsql');
		} else {
			ChangeMode(editor, mode);
		}
	});
	
	$("#theme_selector", $optionsDialog).change(function() {
		var $selectedTheme = $(":selected", this);
		var theme = $selectedTheme.val();

		if (theme != "default") {
			// Load theme CSS dynamically if it is not default
			$("head").append("<link>");
			var css = $("head").children(":last");
			css.attr({
				rel:  "stylesheet",
				type: "text/css",
				href: "assets/codemirror/theme/" + theme + ".css"
			});
		}
		var editor = GetCurrentEditor();
		editor.setOption("theme", theme);
	});
	
	$("#line_numbers_checkbox", $optionsDialog).change(function() {
		var editor = GetCurrentEditor();
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
		var editor = GetCurrentEditor();
		var tabSize = $(this).val();
		if($.isNumeric(tabSize)) {
			$(this).parent().parent().removeClass("error");
			editor.setOption('tabSize', tabSize);
		} else {
			$(this).parent().parent().addClass("error");
		}
	});

});