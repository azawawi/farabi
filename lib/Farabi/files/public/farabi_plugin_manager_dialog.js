/**
 * Plugin Manager Dialog
 */
$(function() {

	var $dialog    = $("#plugin-manager-dialog");

	// Handle the plugin manager action
	$(document).on('action-plugin-manager', function() {
		$("#plugin-manager-dialog").modal('show');
	});

	// Handle OK Button clicks
	$("#ok-button", $actionsDialog).click(function() {
		if($(this).is(':disabled')) {
			// Button is disabled...
			return;
		}
	});

});