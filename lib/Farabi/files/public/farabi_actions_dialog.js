/**
 * Actions Dialog
 */
$(function() {
	
	var $actionsDialog    = $("#actions-dialog");

	// Handle OK Button clicks
	$("#ok-button", $actionsDialog).click(function() {
		if($(this).is(':disabled')) {
			// Button is disabled...
			return;
		}
		
		var $selectedAction = $("#matched-actions :selected", $actionsDialog);
		if($selectedAction.size() > 0) {
			var actionId = $selectedAction.attr('id');
			$actionsDialog.modal('hide');
			$(document).trigger(actionId);
		} else {
			alert("No action is selected");
		}
	});

	var findAction = function() {
		
		// Get the action name
		var action = $("#action-name", $actionsDialog).val();
		
		// Empty the matched actions list
		$("#matched-actions", $actionsDialog).empty();
		
		// OK button is initially disabled
		$("#ok-button", $actionsDialog).attr("disabled","disabled");

		// Submit a POST request to find action
		$.ajax({
			type:    "POST",
			url:     "/find-action",
			data:    { "action": action },
			success: function(matches) {
				
				// process matches and make select list html
				var html = '';
				for(var i = 0; i < matches.length; i++) {
					var a = matches[i];
					html += "<option id='" + a.id + "' "  + 
						((i == 0) ? "selected" : "") + 
						' help="' + a.help + '"' +
						">" + 
						a.name + 
						"</option>";
				}
				
				if(matches.length > 0) {
					// One or more matches, remove OK button disabled state
					$("#ok-button", $actionsDialog).removeAttr("disabled");
				}
				
				// Render HTML
				$("#matched-actions", $actionsDialog).html(html);

				// On each selection change in the matched actions list, display the correspoding help text
				$("#matched-actions", $actionsDialog).change(function() {
					$("#action-help-text", $actionsDialog).html($("#matched-actions :selected", $actionsDialog).attr("help") );
				});
			},
			error:   function(jqXHR, textStatus, errorThrown) {
				console.error("Error:\n" + textStatus + "\n" + errorThrown);
			}
		});
	}
	
	// Open the actions dialog when the actions button is clicked
	$(".actions-button").click(function() {
		$actionsDialog.modal('show');
		$("#action-name").val('').focus();
		findAction();
	});
	
	// Find action on each action name text field change
	var findActionTimeoutId;
	$("#action-name", $actionsDialog).on('input', function() {
		clearTimeout(findActionTimeoutId);
		findActionTimeoutId = setTimeout(findAction, 250);
	});
	
	// Action dialog global key up handler
	$actionsDialog.keyup(function(e) {
		if(e.keyCode == 13) {
			// ENTER triggers an action
			e.preventDefault();
			$("#ok-button", $actionsDialog).click();
		}
	});

	// Action Name key up handler
	$("#action-name", $actionsDialog).keyup(function(e) {
		var keyCode = e.keyCode;
		if(keyCode == 40) {
			// DOWN ARROW triggers a focus on the matched actions list
			e.preventDefault();
			$("#matched-actions", $actionsDialog).focus();
		} else if(keyCode == 13) {
			// ENTER triggers an action
			e.preventDefault();
			$("#ok-button", $actionsDialog).click();
		}
	});
	
});