/**
 * Options Dialog
 * TODO document Options dialog
 */
$(function() {
	var $optionsDialog = $('#options-dialog');
	
	
	$(document).on('action-options', function() {
		$optionsDialog.modal('show');
		$optionsDialog.on('shown', function() {
			$("#mode_selector", $optionsDialog).focus();
		});
	});
	
	$("#mode_selector", $optionsDialog).change(function() {
		var $selectedMode = $(":selected", this);
		var editor = GetCurrentEditor();
		var mode = $selectedMode.val();
		//TODO second parameter should be configurable mime type instead of normal mode
		window.changeMode(editor, mode, mode);
	});
	
	$("#theme_selector", $optionsDialog).change(function() {
		var theme = $(":selected", this).val();

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

	$("#pod_style_selector", $optionsDialog).change(function() {
		$('a[href="#preview-tab"]').click();
	});

	$("#line_numbers_checkbox", $optionsDialog).change(function() {
		var editor = GetCurrentEditor();
		editor.setOption('lineNumbers', $(this).is(':checked'));
	});

	$("#right_side_shown_checkbox",$optionsDialog).change(function() {
		if ( $(this).is(':checked') ) {
			$(".right-side")
				.addClass("span6")
				.show();
			$(".left-side")
				.removeClass("span12")
				.addClass("span6");
		} else {
			$(".right-side")
				.removeClass("span6")
				.hide();
			$(".left-side")
				.removeClass("span6")
				.addClass("span12");
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

	var toggleWhitespace = function() {
		var editors = window.GetEditors();
		var editor;
		var i;
		for(i = 0; i < editors.length; i++) {
			editor = editors[i];
			window.showWhitespace(editor);
		}
	};
	$("#show_spaces_checkbox",$optionsDialog).change(toggleWhitespace);
	$("#show_tabs_checkbox",$optionsDialog).change(toggleWhitespace);

});