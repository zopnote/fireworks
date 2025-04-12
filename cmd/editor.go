/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package fireworks

import "github.com/spf13/cobra"

var editorCmd = &cobra.Command{
	Use:   "editor",
	Short: "Start or interact with the ui tools.",
	Long:  "Starts the editor web application locally and initializes its backend or send and receive information about the ui.",
	Run: func(cmd *cobra.Command, args []string) {

	},
}

func init() {
	rootCmd.AddCommand(editorCmd)
}
