/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package fireworks

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
)

var rootCmd = &cobra.Command{
	Use:    "fireworks",
	Short:  "Manage your Fireworks development.",
	Hidden: true,
	CompletionOptions: cobra.CompletionOptions{
		HiddenDefaultCmd: true,
	},
}

func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		_, _ = fmt.Fprint(os.Stderr, "There is an error occurred.")
		os.Exit(1)
	}
	os.Exit(0)
}
