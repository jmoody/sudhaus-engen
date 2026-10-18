// Command sudhaus-engen runs the Sudhaus Engen web server.
package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jmoody/sudhaus-engen/internal/web"
)

const (
	defaultPort       = "8000"
	readHeaderTimeout = 5 * time.Second
	shutdownTimeout   = 10 * time.Second
)

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
	if err := run(logger); err != nil {
		logger.Error("server failed", "error", err)
		os.Exit(1)
	}
}

func run(logger *slog.Logger) error {
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	site, err := web.NewServer(logger)
	if err != nil {
		return fmt.Errorf("creating web server: %w", err)
	}

	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           site.Handler(),
		ReadHeaderTimeout: readHeaderTimeout,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	errCh := make(chan error, 1)
	go func() {
		logger.InfoContext(ctx, "listening", "addr", srv.Addr)
		errCh <- srv.ListenAndServe()
	}()

	select {
	case serveErr := <-errCh:
		return fmt.Errorf("serving: %w", serveErr)
	case <-ctx.Done():
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()
	if shutdownErr := srv.Shutdown(shutdownCtx); shutdownErr != nil {
		return fmt.Errorf("shutting down: %w", shutdownErr)
	}
	return nil
}
