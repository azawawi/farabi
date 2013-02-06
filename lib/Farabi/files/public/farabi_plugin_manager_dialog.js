/**
 * Plugin Manager Dialog
 */
$(function() {

	var $dialog    = $("#plugin-manager-dialog");

	// Handle the plugin manager action
	$(document).on('action-plugin-manager', function() {
		$dialog.modal('show');
		
		$dialog.on('shown', function() {

			// Submit a POST request to find plugins
			$.ajax({
				type:    "POST",
				url:     "/find-plugins",
				success: function(plugins) {

					// Create plugin HTML table
					var html = '<thead>' +
						'<tr>' +
						'<th>Plugin</th>' +
						'<th>Plugin Name</th>' +
						'<th>Status</th>' +
						'</tr>' +
						'</thead>';
					html += '<tbody>';
					for(var i = 0; i < plugins.length; i++) {
						var plugin = plugins[i];
						html += '<tr>' +
							'<td>' +  plugin.id + '</td>' +
							'<td>' +  plugin.name + '</td>' +
							'<td>' +  plugin.status + '</td>' +
							'</tr>';
					}
					html += '</tbody>';
	
					// Render HTML
					$("#plugin-table", $dialog).html(html);
	
				},
				error:   function(jqXHR, textStatus, errorThrown) {
					console.error("Error:\n" + textStatus + "\n" + errorThrown);
				}
			});

		});
	});



	// Handle OK Button clicks
	$("#ok-button", $dialog).click(function() {
		if($(this).is(':disabled')) {
			// Button is disabled...
			return;
		}
	});

});