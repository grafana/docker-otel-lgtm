package main

import (
	"fmt"
	"log"
	"math/rand/v2"
	"net/http"
)

func main() {
	http.HandleFunc("/rolldice", func(w http.ResponseWriter, _ *http.Request) {
		result := rand.IntN(6) + 1 //nolint:gosec // dice roll, no crypto needed
		log.Printf("Anonymous player is rolling the dice: %d", result)
		if _, err := fmt.Fprint(w, result); err != nil {
			log.Printf("Writing dice response: %v", err)
		}
	})

	log.Println("Starting server on :8081")
	log.Fatal(http.ListenAndServe(":8081", nil)) //nolint:gosec // simple demo server
}
