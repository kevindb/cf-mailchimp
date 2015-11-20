component displayname="MailChimp" output=true {
	variables.apiHost = "https://us1.api.mailchimp.com/3.0/";
	variables.apiKey = "";

	public mailchimp function init (
		required string apiKey,
				 string apiHost = ""
	) {
		if (len(arguments.apiKey) > 0) {
			variables.apiKey = arguments.apiKey;

			if (len(arguments.apiHost) > 0) {
				variables.apiHost = arguments.apiHost;
			} else {
				local.dc = listLast(variables.apiKey, "-");
				variables.apiHost = replace(variables.apiHost, "us1", local.dc);
			}
		}

		return this;
	}

	private struct function get (
		required string endpoint
	) {
		local.url = variables.apiHost & arguments.endpoint;

		local.httpService = new http(url=local.url, method="get", password=variables.apiKey, username="");
		local.httpContent = httpService.send().getPrefix().fileContent;
		local.responseJson = deserializeJSON(local.httpContent);

		return local.responseJson;
	}
}