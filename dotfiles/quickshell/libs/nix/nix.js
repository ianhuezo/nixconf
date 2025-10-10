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
	nixString = nixString.replace(/#.*/g, '');
	nixString = nixString.trim();
	nixString = nixString.replace(/(\w+)\s*=\s*/g, '"$1": ');
	nixString = nixString.replace(/;/g, ',');
	nixString = nixString.replace(/,(\s*})/g, '$1');
	return JSON.parse(nixString);
}
