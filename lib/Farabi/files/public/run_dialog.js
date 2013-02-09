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
		$runDialog.on('shown', function() {
			$("#runtime", $runDialog).focus().change();
		});
	});

	$("#runtime", $runDialog).keypress(function(e) {
		if(e.keyCode == 13) {
			e.preventDefault();
			$("#ok-button", $runDialog).click();
		}
	});

	var runtimeHelp = {
		"coffeescript"    : {
			text    : "<b>CoffeeScript</b> is a little language that compiles into JavaScript. Underneath all those awkward braces and semicolons, JavaScript has always had a gorgeous object model at its heart. CoffeeScript is an attempt to expose the good parts of JavaScript in a simple way.",
			url     : "http://coffeescript.org",
		},
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
		if(runtime == "coffeescript") {
			// CoffeeScript
			if(typeof CoffeeScript != 'undefined') {
				runOnCoffeeScript(editor.getValue());
			} else {
				// Load CoffeeScript compiler and then run
				$.ajax({
					url: 'assets/coffeescript/coffee-script.js',
					dataType: "script",
					success: function() {
						runOnCoffeeScript(editor.getValue());
					}
				});
			}

		} else if(runtime == "perlito-6") {
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
			window.sendMessage('run-perl', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "rakudo") {
			// Rakudo Perl 6
			window.sendMessage('run-rakudo', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "parrot") {
			// Rakudo Perl 6
			window.sendMessage('run-parrot', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		} else if(runtime == "niecza") {
			// Niecza
			window.sendMessage('/run-niecza', {"source": editor.getValue() }, function(result) {
				show_cmd_output(result);
			});
		}
	});


	var show_cmd_output = function(data) {
		var outputEditor = GetOutputEditor();
		outputEditor.setValue('');

		// Handle STDERR
		if (data.stderr.length) {
			outputEditor.setValue(data.stderr + "\n");
		}

		// Handle STDOUT
		outputEditor.setValue(outputEditor.getValue() + data.stdout + "\nExit code: " + data.exit);

		// Show output tab
		$('a[href="#output-tab"]').tab('show');
	};

	var runOnPerlito5 = function(source) {

		var outputEditor = GetOutputEditor();

		// CORE.print prints to output tab
		p5pkg.CORE.print = function(List__) {
			var i;
			for (i = 0; i < List__.length; i++) {
				outputEditor.setValue( outputEditor.getValue() + p5str(List__[i]));
			}
			return true;
		};

		// CORE.warn print to output tab
		p5pkg.CORE.warn = function(List__) {
			var i;
			List__.push("\n");
			for (i = 0; i < List__.length; i++) {
				outputEditor.setValue( outputEditor.getValue() + p5str(List__[i]));
			}
			return true;
		};

		// Define version, strict and warnings
		p5pkg["main"]["v_^O"] = "browser";
		p5pkg["main"]["Hash_INC"]["Perlito5/strict.pm"] = "Perlito5/strict.pm";
		p5pkg["main"]["Hash_INC"]["Perlito5/warnings.pm"] = "Perlito5/warnings.pm";

		p5make_sub("Perlito5::IO", "slurp", function(filename) {
			console.error('IO.slurp "' + filename + '"');
			return 1;
		});

		p5is_file = function(filename) {
			console.error('p5is_file "' + filename + '"');
			return 1;
		}

		// Clear up output
		outputEditor.setValue('');

		try {
			// Compile Perl 5 source code into JavaScript
			var start = $.now();
			var js_source = p5pkg["Perlito5"].compile_p5_to_js([source]);

			// Run JavaScript inside your browser
			start = $.now();;
			eval(js_source);

		}
		catch(err) {
			// Populate error and show error in output tab
			outputEditor.setValue("Error:\n" + err + "\nCompilation aborted.\n");
		}

		// Show output tab
		$('a[href="#output-tab"]').tab('show');

	};

	var runOnPerlito6 = function(source) {
		var outputEditor = GetOutputEditor();
		window.print = function(s) {
			outputEditor.setValue(outputEditor.getValue() + "\n");
		}
		var ast;
		var match;
		outputEditor.setValue('');
		try {
			// compilation unit
			match = Perlito6$Grammar.exp_stmts(source, 0);
			ast = match.scalar();
			tmp = {v_name:"GLOBAL", v_body: ast}; 
			tmp.__proto__ = CompUnit; 
			ast = tmp;
			eval(ast.emit_javascript());
		} catch(err) {
			// Show error in output tab
			outputEditor.setValue("Error:\n" + perl(err) + "\nCompilation aborted.\n");
		}

		// Show output tab
		$('a[href="#output-tab"]').tab('show');
	};

	// CoffeeScript Compiler
	var runOnCoffeeScript = function(source) {

		var compileSource = function(source) {
		  var el;
		  window.compiledJS = '';
		  try {
			window.compiledJS = CoffeeScript.compile(source, {
			  bare: true
			});
		  } catch (error) {
			alert(error.message);
		  }
		};

		var evalJS = function() {
		  try {
			return eval(window.compiledJS);
		  } catch (error) {
			return alert(error);
		  }
		};

		compileSource(source);
		evalJS();
	};

});
