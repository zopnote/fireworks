/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package fireworks

import "github.com/spf13/cobra"

var PubCommand = &cobra.Command{
	Use:   "pub",
	Short: "Manage dependencies of the Dart ecosystem.",
	Long:  "Manage pub package manager dependencies of your project.",
	Run: func(cmd *cobra.Command, args []string) {

	},
}

func init() {
	RootCmd.AddCommand(PubCommand)
}
