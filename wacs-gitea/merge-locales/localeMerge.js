import fs from "fs";
import ini from "ini";
import path from "path";
import {fileURLToPath} from "url";

// Define directory paths
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const customLocalesDir = path.resolve(
  __dirname,
  "../wacs-gitea/custom/options/locale"
);
const baseLocalesDir = path.join(__dirname, "test-prod-locale");
const outputDir = customLocalesDir;
const customLocales = fs.readdirSync(customLocalesDir);

// Loop through each custom locale
customLocales.forEach((customLocale) => {
  const customLocalePath = path.join(customLocalesDir, customLocale);
  const baseLocalePath = path.join(baseLocalesDir, customLocale);

  // Check if the base locale file exists
  if (fs.existsSync(baseLocalePath)) {
    const customData = ini.parse(fs.readFileSync(customLocalePath, "utf-8"));
    console.log({customData});
    const baseData = ini.parse(fs.readFileSync(baseLocalePath, "utf-8"));

    // Combine keys as specified
    for (const key in customData) {
      console.log(key);
      if (typeof customData[key] == "object") {
        for (const nestedKey in customData[key]) {
          // Add if not exists, and overwrite if does
          console.log(baseData[key][nestedKey]);
          console.log(customData[key][nestedKey]);
          baseData[key][nestedKey] = customData[key][nestedKey];
        }
      } else {
        // Add if not exists, and overwrite if does
        baseData[key] = customData[key];
      }
      console.log(typeof customData[key]);
    }

    // Write the combined data to the output directory
    const outputPath = path.join(outputDir, customLocale);

    console.log({baseData});
    fs.writeFileSync(outputPath, ini.stringify(baseData));
    console.log(`Combined and saved ${customLocale} to ${outputPath}`);
  } else {
    console.log(`Base locale file not found for ${customLocale}`);
  }
});
