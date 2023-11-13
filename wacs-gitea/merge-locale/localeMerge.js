import fs from "fs";
import ini from "ini";
import path from "path";

const waLocaleDir = "/wa-locale";
const giteaLocaleDir = "/gitea-locale";
const outputDir = "/output-locale";
const waLocaleFiles = fs.readdirSync(waLocaleDir);

// Loop through each custom locale
waLocaleFiles.forEach((waLocale) => {
  const waLocalePath = path.join(waLocaleDir, waLocale);
  const giteaLocalePath = path.join(giteaLocaleDir, waLocale);

  // Check if the gitea locale file exists
  if (fs.existsSync(giteaLocalePath)) {
    const waData = ini.parse(fs.readFileSync(waLocalePath, "utf-8"));
    console.log({waLocalePath});
    const giteaData = ini.parse(fs.readFileSync(giteaLocalePath, "utf-8"));

    // Combine keys as specified
    for (const key in waData) {
      if (typeof waData[key] == "object") {
        for (const nestedKey in waData[key]) {
          if (!giteaData[key]) {
            giteaData[key] = {}
          }
          // Add if not exists, and overwrite if does
          giteaData[key][nestedKey] = waData[key][nestedKey];
        }
      } else {
        // Add if not exists, and overwrite if does
        giteaData[key] = waData[key];
      }
    }

    // Write the combined data to the output directory
    const outputPath = path.join(outputDir, waLocale);

    fs.writeFileSync(outputPath, ini.stringify(giteaData));
    console.log(`Combined and saved ${waLocale} to ${outputPath}`);
  } else {
    console.log(`gitea locale file not found for ${waLocale}`);
  }
});
