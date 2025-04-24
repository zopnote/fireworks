/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package fireworks

import (
	"github.com/spf13/cobra"
)

var repairCmd = &cobra.Command{
	Use:   "repair",
	Short: "Tries to repair the tool.",
	Long:  "Renew artifacts and bundles, clean up caches and check for the files integrity.",
	Run: func(cmd *cobra.Command, args []string) {

	},
}

func init() {
	repairCmd.Flags().Bool("force", false, "Will repair the tool without compromises dedicated to user data.")
	rootCmd.AddCommand(repairCmd)
}
