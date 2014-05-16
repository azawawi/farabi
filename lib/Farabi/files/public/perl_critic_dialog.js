/**
 * Perl Critic Dialog
 * TODO document Perl Critic dialog
 */
$(function() {
	var $dialog = $('#perl-critic-dialog');
	
	$(document).on('action-perl-critic', function() {
		perlCritic();
	});

	var widgets = [];

	var perlCritic = function() {
		var editor = GetCurrentEditor();
		$.post(
			'perl_critic', 
			{
				"source": editor.getValue(), 
				"severity": $(':selected', '#critic_severity_selector').val()
			}, 
			function(problems)  
			{

				for (var i = 0; i < widgets.length; i++) {
					editor.removeLineWidget(widgets[i].widget);
				}
				widgets.length = 0;

				problemCount = problems.length;

				//TODO temporary solution until we can figure out how to cooperate
				$(".farabi-error-icon").remove();

				var html = '';

				if(problems.length > 0) {

					html += "<thead>" +
						"<th>Line</th>" +
							"<th>Message</th>" +
								"<th>File</th>" +
									"<th>Source</th>" +
										"</thead>";
					html += "<tbody>";
					
					var id = 0;

					var showTab = function() {
						$('a[href="#problems-tab"]').tab('show');
					};

					for(i = 0; i < problems.length; i++) {
						var problem = problems[i];

						// Add warning or error under the editor line
						var msg = document.createElement("div");
						var icon = msg.appendChild(document.createElement("span"));
						icon.innerHTML = "!!";
						icon.className = "farabi-error-icon";
						msg.appendChild(document.createTextNode(problem.description));
						msg.className = "farabi-error";

						widgets.push({
							problem      : problem,
							widget       : editor.addLineWidget(problem.line_number - 1, msg, {coverGutter: true, noHScroll: true}),
							id           : id
						});

						$(msg).click(showTab);

						html += 
							'<tr id="' + id + '">' +
								'<td class="problem-line">' + problem.line_number + "</td>" +
									"<td>" + problem.description + "</td>" +
										"<td></td>" +
											"<td>Perl::Critic</td>" +
												"</tr>";

						id++;
					}
					
					html += "</tbody>";
				} else {
					html = '<tr>' +
						'<td><span class="badge badge-success">No problems found</span></td>' +
							'</tr>';
				}

				$("#problems > table").html(html);
				$("#problems>  table > tbody > tr").click(function() { 
					var line = parseInt($(".problem-line", this).text(), 10);
					var editor = GetCurrentEditor();
					editor.setCursor({line: line - 1, ch: 0});

					var problem;
					for(var i = 0; i < widgets.length; i++) {
						if(widgets[i].id == $(this).attr("id")) {
							problem  = widgets[i].problem;
							break;
						}
					} 
					
					if(!problem) {
						return;
					}
					
					var policy = problem.policy;
					var html = '<strong>Explanation:</strong><br/>' + problem.explanation;
					html += '<br/><strong>Policy:</strong><br/><a target="_blank" href="https://metacpan.org/module/' + policy + '">' + policy + '</a>';
					html += '<br/><strong>Diagnositcs:</strong><br/>' + problem.diagnostics.replace(/\n/g, '<br/>');
					
					$('#myModalLabel', $dialog).html(
						problem.description
					);
					$('.modal-body', $dialog).html(html);
					$dialog.modal("show");
				});

				// Update editor statistics
				window.showEditorStats(editor);

		});

	};

	$("#critic_severity_selector").change(function() {
		perlCritic();
	});

});