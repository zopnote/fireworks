/*
 * Copyright (c) 2025 Lenny Siebert. All rights reserved.
 *
 * Project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.
 */

package pkg

import (
	"fmt"
	"log"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	_, err := fmt.Fprintf(w, "Hello, World!")
	if err != nil {
		fmt.Printf("Error: %v\n", err)
	}
}

func start() {
	http.HandleFunc("/", handler)

	fmt.Println("Server läuft auf http://localhost:8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
