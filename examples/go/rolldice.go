package main

import (
	"fmt"
	"io"
	"log/slog"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
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

	histogram, err := meter.Int64Histogram("dice.roll", metric.WithDescription("The result of the dice roll"))
	if success := (err == nil); !success {
		logger.ErrorContext(ctx, "Histogram instantiation failed: %v\n", slog.Any("error", err))
	} else {
		histogram.Record(ctx, int64(roll), metric.WithAttributes(attribute.Bool("result.success", success)))
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
