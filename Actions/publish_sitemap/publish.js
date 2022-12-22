
// Send generated sitemap to google servers

const { google } = require('googleapis');
const { JWT } = require('google-auth-library');
const searchconsole = google.searchconsole('v1');

// GOOGLE_SEARCH_CONSOLE_KEY is a repository secret set in: Repo -> Settings -> Secrets -> Actions
// PowerShell:
// $Data = Get-Content -Path keys.json -Encoding utf8
// $GOOGLE_SEARCH_CONSOLE_KEY = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Data))
// Set-Clipboard -Value $GOOGLE_SEARCH_CONSOLE_KEY
// TODO: Resolve "The first argument must be of type string or an instance of Buffer, ArrayBuffer, or Array or an Array-like Object. Received undefined"
const buffer = Buffer.from(process.env.GOOGLE_SEARCH_CONSOLE_KEY, 'base64').toString('utf-8');
const keys = JSON.parse(JSON.stringify(buffer));

// TODO: Resolve "Error: No key or keyFile set."
const client = new JWT({
	email: keys.client_email,
	key: keys.private_key,
	scopes: ['https://www.googleapis.com/auth/webmasters', 'https://www.googleapis.com/auth/webmasters.readonly'],
});

google.options({ auth: client });

(async () => {
	try {
		await searchconsole.sitemaps.submit({
			// TODO: Update this to your own sitemap
			feedpath: 'https://metablaster.github.io/WindowsFirewallRuleset/sitemap.xml',
			siteUrl: 'https://metablaster.github.io/WindowsFirewallRuleset/',
		});

	} catch (e) {
		console.log(e);
	}
})();
