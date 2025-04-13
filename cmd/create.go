/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package fireworks

import (
	"errors"
	"fireworks/internal/source"
	"fmt"
	"github.com/spf13/cobra"
	"os"
	"path/filepath"
)

var templatesPath string

var createCmd = &cobra.Command{
	Use:   "create [name]",
	Short: "Creates a new Fireworks module from a template.",
	RunE: func(cmd *cobra.Command, args []string) error {

		if len(args) < 1 {
			return errors.New("specify a project name")
		} else if len(args) > 1 {
			return errors.New("to many arguments")
		}

		templateName, err := cmd.Flags().GetString("template")
		if err != nil {
			return err
		}

		forced, err := cmd.Flags().GetBool("force")
		if err != nil {
			return err
		}

		workingDir, err := os.Getwd()
		if err != nil {
			return err
		}

		templatedPath := filepath.Join(templatesPath, templateName)
		_, err = os.Stat(templatedPath)
		if err != nil {
			return errors.New(fmt.Sprintf("there is no template with the name %s found", templateName))
		}

		var allowedCharacter = "abcdefghijklmnopqrstuvwxyz1234567890_-."
		for _, char := range args[0] {
			found := false
			for _, allowed := range allowedCharacter {
				if char != allowed {
					continue
				}
				found = true
				break
			}
			if !found {
				return errors.New(fmt.Sprintf("\"%s\" contains '%c' which mades the module name invalid", args[0], char))
			}
		}

		projectPath := filepath.Join(workingDir, args[0], "/")
		_, err = os.Stat(projectPath)
		if err == nil {
			if !forced {
				return errors.New(fmt.Sprintf("there is already a directory \"%s\". Use --force to force the creation", args[0]))
			}
			err = os.RemoveAll(projectPath)
			if err != nil {
				return err
			}
		}

		err = os.CopyFS(projectPath, os.DirFS(templatedPath))
		if err != nil {
			return err
		}
		return nil
	},
}

func init() {

	dataPath, err := internal.GetDataPath()
	if err != nil {
		message := fmt.Sprintf("Fatal error occurred while tried to get the applications internal data: %s", err)

		_, err = fmt.Fprintln(os.Stderr, message)
		if err != nil {
			fmt.Println(message)
		}
	}
	templatesPath = filepath.Join(dataPath, "template/projects/")

	entries, err := os.ReadDir(templatesPath)
	if err != nil {
		_, err = fmt.Fprintln(os.Stderr, fmt.Sprintf("%v", err))
		if err != nil {
			fmt.Println(fmt.Sprintf("%v", err))
		}
	}

	availableTemplates := ""
	for _, entry := range entries {
		availableTemplates = availableTemplates + entry.Name() + "; "
	}

	createCmd.Flags().Bool("force", false, "Forces the process")
	createCmd.Flags().String("template", "standard", fmt.Sprintf("Available: %s", availableTemplates))

	rootCmd.AddCommand(createCmd)
}
