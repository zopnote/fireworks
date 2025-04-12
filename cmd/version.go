package fireworks

import "github.com/spf13/cobra"

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Displays version info about the current installation.",
	Long: "Get information about the version of Fireworks currently installed," +
		" as well as its dependencies that get cached.",
	Run: func(cmd *cobra.Command, args []string) {

	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
