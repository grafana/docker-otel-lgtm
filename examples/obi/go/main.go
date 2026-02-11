package main

import (
	"fmt"
	"log"
	"math/rand/v2"
	"net/http"
)

func main() {
	http.HandleFunc("/rolldice", func(w http.ResponseWriter, _ *http.Request) {
		result := rand.IntN(6) + 1
		log.Printf("Anonymous player is rolling the dice: %d", result)
		fmt.Fprint(w, result)
	})

	log.Println("Starting server on :8081")
	log.Fatal(http.ListenAndServe(":8081", nil))
}
