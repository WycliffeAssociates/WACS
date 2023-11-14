package main

import (
	"fmt"
	"os"
	"path"

	"github.com/go-ini/ini"
)

func main() {
	fmt.Println("Running locale merge script")


	// Define directory paths
	waLocaleDir := path.Join("/wa-locale")
	giteaLocaleDir := path.Join("/gitea-locale")
	outputDir := ("/output-locale")

	// Read custom locales
	waLocaleFiles, err := os.ReadDir(waLocaleDir)
	if err != nil {
		fmt.Println("Error reading custom locales directory:", err)
		os.Exit(1)
	}

	// Loop through each custom locale
	for _, waLocale := range waLocaleFiles {
		waLocalePath := path.Join(waLocaleDir, waLocale.Name())
		giteaLocalePath := path.Join(giteaLocaleDir, waLocale.Name())

		// Check if the base locale file exists
		if _, err := os.Stat(giteaLocalePath); err == nil {
			// Read custom data
			waLocaleData, err := ini.Load(waLocalePath)
			if err != nil {
				fmt.Println("Error loading custom data:", err)
				continue
			}


			// Read base data
			giteaData, err := ini.Load(giteaLocalePath)
			if err != nil {
				fmt.Println("Error loading base data:", err)
				continue
			}

			// Combine keys as specified
			for _, section := range waLocaleData.Sections() {
                // if baseData.HasSection(section.Name()) {
                //     fmt.Println(fmt.Sprintf("It has the same section %s", section.Name()))
                // }

				for _, key := range section.Keys() {
                    fmt.Println(key)
					// Add if not exists, and overwrite if does
					giteaData.Section(section.Name()).Key(key.Name()).SetValue(key.Value())
				}
			}

			// Write the combined data to the output directory
			outputPath := path.Join(outputDir, waLocale.Name())



			err = giteaData.SaveTo(outputPath)
			fmt.Printf("Combined and saved %s to %s\n", waLocale.Name(), outputPath)
			if err != nil {
				fmt.Println("Error saving combined data:", err)
				continue
			}

		} else {
			fmt.Printf("Base locale file not found for %s\n", waLocale.Name())
		}
	}
}
