require.config({
	baseUrl: '/',
	paths: {
		'jquery': 'libs/jquery',
		'backbone': 'libs/backbone',
		'underscore': 'libs/underscore'
	},
	
	shim: {
		'backbone': {
			// These script dependencies should be loaded 
			// before loading backbone.js
			deps: ['underscore', 'jquery'],
			// Once loaded, use the global 'Backbone' 
			// as the module value.
			exports: 'Backbone'
		},
		'underscore': {
			// Use the global '_' as the module value.
			exports: '_'
		}
	}
});

require([
         'org.aksw.sparql'
], function(sparql) {
	alert("Yay");
});