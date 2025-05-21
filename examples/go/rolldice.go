package main

import (
	"fmt"
	"io"
	"log/slog"
	"math/rand"
	"net/http"
	"strconv"
	"time"
)

func rolldice(w http.ResponseWriter, r *http.Request) {
	ctx, span := tracer.Start(r.Context(), "roll")
	defer span.End()

	roll := 1 + roll()

	msg := fmt.Sprintf("Rolled a dice: %d\n", roll)
	logger.InfoContext(ctx, msg, slog.Int("result", roll))

	resp := strconv.Itoa(roll) + "\n"
	if _, err := io.WriteString(w, resp); err != nil {
		logger.ErrorContext(ctx, "Write failed: %v\n", slog.Any("error", err))
	}
}

func roll() int {
	// simulate a long operation
	// busy wait to make sure it's shown in the flame graph
	start := time.Now()
	for time.Since(start) < 1*time.Second {
		// busy wait
	}

	//nolint:gosec
	return rand.Intn(6)
}
