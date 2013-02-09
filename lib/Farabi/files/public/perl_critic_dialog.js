/**
 * Perl Critic Dialog
 * TODO document Perl Critic dialog
 */
$(function() {
	var $perlCriticDialog = $('#perl-critic-dialog');
	
	$(document).on('action-perl-critic', function() {
		perlCritic();
	});

	var perlCriticWidgets = [];

	var perlCritic = function() {
		var editor = GetCurrentEditor();
		window.sendMessage('perl-critic', {"source": editor.getValue(), "severity": $(':selected', '#critic_severity_selector').val()}, function(violations) {
			for (var i = 0; i < perlCriticWidgets.length; i++) {
				editor.removeLineWidget(perlCriticWidgets[i].widget);
			}
			perlCriticWidgets.length = 0;

			if(violations.length > 0) {
				for(var i = 0; i < violations.length; i++) {
					var violation = violations[i];
					var description = violation.description;

					// Add Perl::Critic violation under the editor line
					var msg = $('<div class="farabi-error">' +
						'<span class="farabi-error-icon">!!</span>' + 
						description + '</div>')
						.appendTo(document)
						.get(0);
					perlCriticWidgets.push({
						violation: violation,
						widget:    editor.addLineWidget(violation.line_number - 1, msg, {coverGutter: true, noHScroll: true}),
						node:      msg
					});
				}

				$('.farabi-error').click(function() {
					
					var violation;
					for(var i = 0; i < perlCriticWidgets.length; i++) {
						if(perlCriticWidgets[i].node == this) {
							violation  = perlCriticWidgets[i].violation;
							break;
						}
					} 
					
					if(!violation) {
						return;
					}

					var policy = violation.policy;
					var html = '<strong>Explanation:</strong><br/>' + violation.explanation;
					html += '<br/><strong>Policy:</strong><br/><a target="_blank" href="https://metacpan.org/module/' + policy + '">' + policy + '</a>';
					html += '<br/><strong>Diagnositcs:</strong><br/>' + violation.diagnostics.replace(/\n/g, '<br/>');

					$('#myModalLabel', $perlCriticDialog).html(
						violation.description
					);
					$('.modal-body', $perlCriticDialog).html(html);
					$perlCriticDialog.modal("show");
				});
			}
			
			if(violations.length > 0) {
				alert("Perl Critic: Found " + violations.length + " violation(s)");
			} else {
				alert("Perl Critic: No violations found for current severity level");
			}
		});
	};

	$("#critic_severity_selector").change(function() {
		perlCritic();
	});

});