# CF MailChimp
ColdFusion wrapper for the MailChimp 3.0 API

## Work in Progress
This wrapper is a work in progress. I have prioritized building out the features needed for my projects. 
If there is a feature that you would like added, please [open an issue](https://github.com/kevindb/cf-mailchimp/issues/new) or [submit a pull request](https://github.com/kevindb/cf-mailchimp/pulls).

## List of available methods
- getLists - Retrieves all lists in the account
- getList - Retrieves information about the specified list
- getListMembers - Retrieves a list of all members of the specified list
- getListMember - Retrieves details on a single member of the specified list
- putListMembers - Uses a batch operation to add or update multiple members of the specified list
- putListMember - Adds or updates a single member to the specified list

## Requirements
I have only tested on Adobe ColdFusion 11. I am confident that the wrapper will work in Lucee/Railo 4. It may work in ACF 10 and will NOT work in ACF 9-.

### JSONUtil Dependency
CF MailChimp uses the [JSONUtil](https://github.com/CFCommunity/jsonutil) library for JSON serialization/deserialization instead of ColdFusion's built-in serializer. MailChimp's API will reject data being sent as a boolean or numeric value when it is expecting a string. CF's serializer frequently and silently converts variable types and cannot be controlled.

If you put `JSONUtil.cfc` in the same folder as `mailchimp.cfc`, it will be found automatically.  
If you want to keep `JSONUtil.cfc` in a different folder, then add the argument `jsonUtil` to your `init`, and pass it the normal ColdFusion dot-delimited path to the component.

If `JSONUtil.cfc` cannot be found, CF MailChimp will fall back to using ColdFusion's built-in serializer.

## Community
Want to contribute to CF MailChimp? Awesome! See [CONTRIBUTING](CONTRIBUTING.md) for more information.

### Code of Conduct
Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md) to ensure that this project is a welcoming place for **everyone** to contribute to. By participating in this project you agree to abide by its terms.

## Usage
```
mc = new mailchimp(
	apiKey = "YOURAPIKEY",	// see http://kb.mailchimp.com/accounts/management/about-api-keys
	serviceURL = "https://us1.api.mailchimp.com/3.0/",
	debug = true			// note debug setting
);

lists = mc.getLists();

newMember = mc.putListMember(
	listId = "YOURLISTID",	// see http://kb.mailchimp.com/lists/managing-subscribers/find-your-list-id
	data = {
		"email_address" = "hey@example.com",
		"status" = "subscribed",
		"merge_fields" = {
			"FNAME" = "Hey",
			"Now" = "Finley",
			"COMPANY" = "Acme"
		}
	}
);
```

## Resources
* [MailChimp API 3.0 Documention](http://developer.mailchimp.com/)
* [JSONUtil ColdFusion JSON library](https://github.com/CFCommunity/jsonutil)

## Contributors
This project is based on previous work by others. 
See [CONTRIBUTORS](CONTRIBUTORS.md) for details.

## License

This repository is licensed under the GNU Lesser General Public License v2.1. 
See [LICENSE](LICENSE) for details.
