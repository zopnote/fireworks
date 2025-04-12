package fireworks

import "github.com/spf13/cobra"

var getCmd = &cobra.Command{
	Use:   "get",
	Short: "Loads the module specification and generates support for indexing.",
	Long: "Fetches the dependencies and make them available for your application. " +
		"Also generates the necessary information for your ide to work with the project.",
	Run: func(cmd *cobra.Command, args []string) {

	},
}

func init() {
	rootCmd.AddCommand(getCmd)
}
