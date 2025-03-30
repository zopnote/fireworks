/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package fireworks

import (
	"fmt"
	"github.com/spf13/cobra"
)

var RootCmd = &cobra.Command{
	Use:   "mycli",
	Short: "A simple CLI tool",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Welcome to My CLI tool!")
	},
}
