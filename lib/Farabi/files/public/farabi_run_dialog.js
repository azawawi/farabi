/**
 * Run dialog
 *
 * TODO document Run dialog
 */
$(function() {
	var $runDialog = $("#run-dialog");

	$(document).on('action-run', function() {
		// Run file
		$runDialog.modal('show');
		$("#runtime", $runDialog).focus().change();
	});

	$("#runtime", $runDialog).keypress(function(e) {
		if(e.keyCode == 13) {
			e.preventDefault();
			$("#ok-button", $runDialog).click();
		}
	});

	var runtimeHelp = {
		"rakudo"    : {
			text    : "<b>Rakudo</b> Perl 6, or simply Rakudo, is a compiler for the Perl 6 programming language. It runs on the Parrot virtual machine.",
			url     : "http://rakudo.org/about",
		},
		"niecza"    : {
			text    : "<b>Niecza</b> is a Perl 6 implementation focusing on optimization and efficient implementation research. It targets the Common Language Runtime (<a href='http://en.wikipedia.org/wiki/Common_Language_Infrastructure' target='_blank'>ECMA-335</a>; implementations are 'Mono' and '.NET').",
			url     : "https://github.com/sorear/niecza/blob/master/README.pod",
		},
		"parrot"    : {
			text   : "<b>Parrot</b> is a virtual machine designed to efficiently compile and execute bytecode for dynamic languages.",
			url    : "http://www.parrot.org/",
		},
		"perl": {
			text    : "<b>Perl 5</b> is a highly capable, feature-rich programming language with over 24 years of development.",
			url     : "http://perl.org",
		},	
		"perlito-6" : {
			text    : "<b>Perlito 6</b> is a compiler collection that implements a subset of Perl 6.",
			url     : "http://perlito.org",
		},
		"perlito-5" : {
			text    : "<b>Perlito 5</b> is a compiler collection that implements a subset of Perl 5.",
			url     : "http://perlito.org",
		},
	};

	$("#runtime").change(function() {
		var runtime = $(":selected", $(this)).attr('id');
		var help = runtimeHelp[runtime];
		$("#help", $runDialog).html(help.text + "<br><a href='" + help.url + "' target='_blank'>More information...</a>");
	});

	$("#ok-button", $runDialog).click(function() {
		var editor = window.GetCurrentEditor();
		var runtime = $("#runtime :selected", $runDialog).attr('id');
		if(runtime == "perlito-6") {
			// Perlito 6
			if(typeof p6pkg != 'undefined') {
                                runOnPerlito6(editor.getValue());
                        } else {
                                // Load Perlito and then run
                                $.ajax({
                                        url: 'assets/perlito/perlito6.min.js',
                                        dataType: "script",
                                        success: function() {
                                                runOnPerlito6(editor.getValue());
                                        }
                                });
                        }
		} else if(runtime == "perlito-5") {
			// Perlito 5
			if(typeof p5pkg != 'undefined') {
				runOnPerlito5(editor.getValue());
			} else {
				// Load Perlito and then run
				$.ajax({
					url: 'assets/perlito/perlito5.min.js',
					dataType: "script",
					success: function() {
						runOnPerlito5(editor.getValue());
					}
				});
			}
		} else if(runtime == "perl") { 
			// Perl
			$.post('/run-perl', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "rakudo") {
			// Rakudo Perl 6
			$.post('/run-rakudo', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "parrot") {
			// Rakudo Perl 6
			$.post('/run-parrot', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "niecza") {
			// Niecza
			$.post('/run-niecza', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		}
	});


	var show_cmd_output = function(data) {
		var $output = $('#output');
		$output.val('');
			
		// Handle STDERR
		if (data.stderr.length) {
			$output.val(data.stderr + "\n");
		}
		
		// Handle STDOUT
		$output.val($output.val() + data.stdout + "\nExit code: " + data.exit);
	};

});