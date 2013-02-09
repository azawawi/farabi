/**
 * Save Question dialog
 *
 * TODO document save question dialog
 */
$(function() {
	var $saveQuestionDialog    = $("#save-question-dialog");

	$("#yes-button", $saveQuestionDialog).click(function() {

		$.ajax({
			type:    "POST",
			url:     "/save-file",
			data:    { 
				"filename": GetCurrentFilename(), 
				"contents": GetCurrentEditor().getValue() 
			},
			success: function(result) {
			},
			error:   function(jqXHR, textStatus, errorThrown) {
				console.error("Error!" + textStatus + ", " + errorThrown);
			}
		});
	});

	$("#no-button", $saveQuestionDialog).click(function() {

		console.error("Not gonna save :)");
	});
	
});