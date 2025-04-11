/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package main

import (
	fireworks "fireworks/cmd"
	"fmt"
	"github.com/spf13/cobra"
	"os"
	"time"
)

func main() {
	cobra.MousetrapHelpText = fireworks.RootHelpMsg
	cobra.MousetrapDisplayDuration = time.Minute
	if err := fireworks.RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
