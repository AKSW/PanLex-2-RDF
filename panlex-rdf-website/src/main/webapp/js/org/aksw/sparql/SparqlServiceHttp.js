var sparql = {};

/**
 * Sparql endpoint class:
 * Allows execution of sparql queries against a preconfigured service
 * 
 * @param serviceUrl
 * @returns {VirtuosoSparqlService}
 */
// Guard function for JQuery and underscore
(function($, _) {
		
// A wrapper function to allow using arbitrary objects as namespaces.
// Hopefully makes "refactoring" more easy 
(function(ns) {

	/**
	 * SparqlServiceHttp
	 * 
	 * @param extraArgs: A set of additional arguments to pass via the query string
	 */
	ns.SparqlServiceHttp = function(serviceUri, defaultGraphUris, proxyServiceUri, proxyParamName) {
		this.serviceUri = serviceUri;
		
		this.proxyServiceUri = proxyServiceUri;
		this.proxyParamName = proxyParamName ? proxyParamName : "service-uri"; 
		
		this.setDefaultGraphs(defaultGraphUris);
		
		//this.extraArgs = extraArgs; 
	};
	
	
	ns.SparqlServiceHttp.prototype = {
			setDefaultGraphs: function(uriStrs) {
				this.defaultGraphUris = uriStrs ? uriStrs : [];
			},
	
			getDefaultGraphs: function() {
				return this.defaultGraphUris;
			},
	
			executeAny: function(queryString) {
		
				if(!queryString) {
					console.error("Empty queryString - should not happen");
				}

				var options = {};
				var serviceUri = this.serviceUri;
		
				if(this.proxyServiceUri) {
					options[this.proxyParamName] = serviceUri;
					serviceUri = this.proxyServiceUri;
				}
		
		
				var result = ns.executeQuery(serviceUri, this.defaultGraphUris, queryString, options);
			
				return result;
			},
	
	
	
			executeSelect: function(query) {
				return this.executeAny(query);
			},
	
			executeAsk: function(query) {
				return this.executeAny(query);
			},
	
			// TODO What to return: RdfJson vs RdfQuery
			executeConstruct: function(query) {
				return this.executeAny(query);
			},
	
	
			executeDescribe: function(query) {
				return this.executeAny(query);
			}
	};

	
	/*
	 * SparqlServiceDelay 
	 */

	
	ns.SparqlServiceDelay = function(delegate, delay) {
		this.delegate = delegate;
		this.scheduler = new Scheduler(delay); 
	};
	
	ns.SparqlServiceDelay.prototype = { 
			executeSelect: function(queryString, callback) {
				return delegate.executeSelect(queryString, callback);
			},
	
			executeAsk: function(queryString, callback) {
				return delegate.executeAsk(queryString, callback);
			}
	};

	


	
	

	
	
	/**
	 * Adapted from http://www.openlinksw.com/blog/~kidehen/?id=1653
	 * 
	 * @param baseURL
	 * @param query
	 * @param callback
	 * @param format
	 */
	ns.executeQuery = function(baseURL, defaultGraphUris, query, options) {
		if(!options) {
			options = {};
		}
		
		if(!options.format) {
			// FIXME Should not modify options object
			options.format="application/json";
		}
		
		/*
		var params={
			"default-graph": "", "should-sponge": "soft", "query": query,
			"debug": "on", "timeout": "", "format": format,
			"save": "display", "fname": ""
		};
		*/
		var params = _.map(defaultGraphUris, function(item) {
			var pair = {key: "default-graph-uri", value: item };
			return pair;
		});
		
		params.push({key: "query", value: query});
		//params.push({key: "format", value: format});
	
		_.each(options, function(v, k) {
			params.push({key: k, value: v});
		});
		
		var querypart="";
		_.each(params, function(param) {
			//querypart+=k+"="+encodeURI(params[k])+"&";
			querypart+=param.key+"="+encodeURIComponent(param.value)+"&";
		});

		var url = baseURL + "?" + querypart;
		//alert("url: " + url);
		
		//return $.post(baseURL, querypart);
		var result = $.ajax({
			url: url,
			dataType: 'json'
		});
			
		return result;
	};

	})(sparql || (sparql = {}));
		
})(jQuery, _);

