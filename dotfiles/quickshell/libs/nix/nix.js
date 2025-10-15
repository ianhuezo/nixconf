var jsonToNix = (obj, indent = 0) => {
	const spaces = "  ".repeat(indent);
	const lines = [];

	for (const [key, value] of Object.entries(obj)) {
		if (typeof value === "object" && value !== null) {
			lines.push(`${spaces}${key} = ${jsonToNix(value, indent + 1)};`);
		} else {
			lines.push(`${spaces}${key} = ${JSON.stringify(value)};`);
		}
	}

	const closingSpaces = indent > 0 ? "  ".repeat(indent - 1) : "";
	return `{\n${lines.join("\n")}\n${closingSpaces}}`;
}

var nixToJson = (nixString) => {
	// Remove actual comments (# not followed by hex digits)
	let lines = nixString.split('\n');
	let cleaned = [];

	for (let i = 0; i < lines.length; i++) {
		let line = lines[i];
		// Remove comments but preserve hex colors
		line = line.replace(/#(?![0-9A-Fa-f]{6})\s*.*/g, '');
		if (line.trim()) {
			cleaned.push(line);
		}
	}

	nixString = cleaned.join('\n').trim();

	// Remove outer braces (if any) and re-wrap
	if (nixString.startsWith('{')) nixString = nixString.slice(1);
	if (nixString.endsWith('}')) nixString = nixString.slice(0, -1);

	nixString = '{' + nixString + '}';

	// Quote hex colors first
	nixString = nixString.replace(/#([0-9A-Fa-f]{6})/g, '"#$1"');

	// --- REFINED VALUE QUOTING TO PREVENT DOUBLE-QUOTES ---
	// Quote unquoted string values, but EXCLUDE values that start with a quote or brace.
	// This prevents double-quoting of 'slug' and prevents misquoting the 'palette' object string.
	nixString = nixString.replace(/=\s*([a-zA-Z0-9\-\.]+\s*[;\}])/g, (match, value) => {
		let trimmedValue = value.trim().slice(0, -1).trim(); // Remove trailing ; or }
		let separator = value.trim().slice(-1); // Keep the trailing ; or }

		// Only quote if it doesn't look like a number or already quoted (though the regex avoids quotes)
		if (trimmedValue.match(/^[0-9\.]+$/)) {
			return '= ' + trimmedValue + separator; // Keep numbers unquoted
		}
		return '= "' + trimmedValue + '"' + separator;
	});

	// Handle string values that were already quoted in the source but need cleanup,
	// like the values for slug, name, and author which might be over-quoted.
	// Replace: = ""value""; or = ""value""; with = "value";
	nixString = nixString.replace(/=\s*"""([^"]*)"""/g, '= "$1"');
	nixString = nixString.replace(/=\s*""([^"]*)""/g, '= "$1"');

	// --- CONVERSION TO JSON SYNTAX ---

	// 1. Convert Nix assignments (key = ) to JSON pairs ("key": )
	// The \b (word boundary) ensures we only catch full keys like 'slug' and not partial matches.
	nixString = nixString.replace(/\b(\w+)\s*=/g, '"$1":');

	// 2. Convert Nix separators (;) to JSON separators (,)
	nixString = nixString.replace(/;/g, ',');

	// 3. Remove trailing commas just before a closing brace
	nixString = nixString.replace(/,(\s*})/g, '$1');

	console.log(nixString);
	return JSON.parse(nixString);
}
